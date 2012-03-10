# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

# We only require net/https to ensure that HTTPS is supported for
# proxy[:secure] requests
begin
  require 'net/https'
  SC::HTTPS_ENABLED = true
rescue LoadError => e
  SC::HTTPS_ENABLED = false
end

begin
  require 'eventmachine'
  require 'em-http'
  require 'thin'

  SC::PROXY_ENABLED = true
rescue LoadError => e
  SC::PROXY_ENABLED = false
end

if SC::PROXY_ENABLED
  # There are cases where we cannot load the proxy and don't need to (build environment)

  module SC

    module Rack

      class DeferrableBody
        include EM::Deferrable

        def initialize(options = {})
          @options = options
        end

        def call(body)
          body.each do |chunk|
            @body_callback.call(prepare_chunk(chunk))
          end
        end

        def prepare_chunk(chunk)
          if chunked?
            size = chunk.respond_to?(:bytesize) ? chunk.bytesize : chunk.length
            "#{size.to_s(16)}\r\n#{chunk}\r\n"
          else
            # Thin doesn't like null bodies
            chunk || ''
          end
        end

        def each(&blk)
          @body_callback = blk
        end

      private

        def chunked?
          @options[:chunked]
        end
      end


      # clears host field from request header if it's redirected request
      class RedirectHostHeaderKiller

        def response(r)
          if r.redirect?
            puts r.req.headers
            r.req.headers.delete('Host')
          end
        end

      end


      # Rack application proxies requests as needed for the given project.
      class Proxy

        def initialize(project)
          @project = project
          @proxies = project.buildfile.proxies
        end

        def call(env)
          path = env['PATH_INFO']

          @proxies.each do |proxy, value|
            # If the url matches a proxied url, handle it
            if path.match(/^#{Regexp.escape(proxy.to_s)}/)
              handle_proxy(value, proxy.to_s, env)

              # Don't block waiting for a response
              throw :async
            end
          end

          return [404, {}, "not found"]
        end

        def chunked?(headers)
          headers['Transfer-Encoding'] == "chunked"
        end

        def handle_proxy(proxy, proxy_url, env)

          if proxy[:secure] && !SC::HTTPS_ENABLED
            SC.logger << "~ WARNING: HTTPS is not supported on your system, using HTTP instead.\n"
            SC.logger << "    If you are using Ubuntu, you can run `apt-get install libopenssl-ruby`\n"
            proxy[:secure] = false
          end

          headers = request_headers(env, proxy)         # ex. {"Host"=>"localhost:4020", "Connection"=>"...
          path = env['PATH_INFO']                       # ex. /contacts
          params = env['QUERY_STRING']                  # ex. since=yesterday&unread=true

          # Switch to https if proxy[:secure] configured
          protocol = proxy[:secure] ? 'https' : 'http'

          # Adjust the path if proxy[:url] configured
          if proxy[:url]
            path = path.sub(/^#{Regexp.escape proxy_url}/, proxy[:url])
          end

          # The endpoint URL
          url = protocol + '://' + proxy[:to]
          url += path unless path.empty?
          url += '?' + params unless params.empty?

          if env['CONTENT_LENGTH'] || env['HTTP_TRANSFER_ENCODING']
            req_body = env['rack.input']
            req_body.rewind # May not be necessary but can't hurt

            req_body = req_body.read
          end

          # Options for the connection
          connect_options = {}
          if proxy[:inactivity_timeout] # allow the more verbose setting to take precedence
            connect_options[:inactivity_timeout] = proxy[:inactivity_timeout]
          elsif proxy[:timeout] # check the legacy and simpler setting
            connect_options[:inactivity_timeout] = proxy[:timeout]
          end
          connect_options[:connect_timeout] = proxy[:connect_timeout] if proxy[:connect_timeout]

          # Options for the request
          request_options = {}
          request_options[:head] = headers
          request_options[:body] = req_body if !!req_body
          request_options[:redirects] = 5 if proxy[:redirect] != false
          request_options[:decoding] = false  # don't decode gzipped content

          EventMachine.run {
            body = nil
            conn = EM::HttpRequest.new(url, connect_options)
            chunked = false
            headers = {}
            method = env['REQUEST_METHOD'].upcase
            status = 0
            conn.use RedirectHostHeaderKiller

            case method
              when 'GET'
                http = conn.get request_options
              when 'POST'
                http = conn.post request_options
              when 'PUT'
                http = conn.put request_options
              when 'DELETE'
                http = conn.delete request_options
              else
                http = conn.head request_options
              end

            # Received error
            http.errback {
              status = http.response_header.status
              path = env['PATH_INFO']
              url = http.last_effective_url
              SC.logger << "~ PROXY FAILED:  #{method} #{path} -> #{status} #{url}\n"

              # If a body has been sent use it, otherwise respond with generic message
              if !body
                body = "Unable to proxy to #{url}.  Received status: #{status}"
                size = body.respond_to?(:bytesize) ? body.bytesize : body.length
                headers = { 'Content-Length' => size.to_s }
                body = [body]
              end

              env['async.callback'].call [502, headers, body]
            }

            # Received response
            http.callback {

              # Too many redirects
              if redirect? status
                body = "Unable to proxy to #{url}.  Too many redirects."
                size = body.respond_to?(:bytesize) ? body.bytesize : body.length
                headers = { 'Content-Length' => size.to_s }

                env['async.callback'].call [502, headers, [body]]
              else
                # Terminate the deferred body (which may have been chunked)
                if body
                  body.call ['']
                  body.succeed
                end

                # Log the initial path and the final url
                path = env['PATH_INFO']
                url = http.last_effective_url
                SC.logger << "~ PROXY: #{method} #{path} -> #{status} #{url}\n"
             end
            }

            # Received headers
            http.headers { |hash|
              status = http.response_header.status

              headers = response_headers(hash)

              # Don't respond on redirection, but fail out on bad redirects
              if redirect? status

                if status == 304
                  env["async.callback"].call [status, headers, ['']]
                  SC.logger << "~ PROXY: #{method} #{path} -> #{status} #{url}\n"
                elsif !headers['Location']
                  body = "Unable to proxy to #{url}. Received redirect with no Location."
                  size = body.respond_to?(:bytesize) ? body.bytesize : body.length
                  headers = { 'Content-Length' => size.to_s }

                  http.close
                end

              else
                # Stream the body right across in the format it was sent
                chunked = chunked?(headers)
                body = DeferrableBody.new({ :chunked => chunked })

                # Start responding to the client immediately
                env["async.callback"].call [status, headers, body]
              end
            }

            # Received chunk of data
            http.stream { |chunk|
              # Ignore body of redirects
              if !redirect? status
                body.call [chunk]
              end
            }

            # If the client disconnects early, make sure we close our other connection too
            # TODO: this is waiting for changes not yet available in em-http
            # Test with: curl http://0.0.0.0:4020/stream.twitter.com/1/statuses/sample.json -uTWITTER_USERNAME:TWITTER_PASSWORD
            # env["async.close"].callback {
            #   conn.close
            # }

          }
        end

        def redirect?(status)
          status >= 300 && status < 400
        end

        # collect headers...
        def request_headers(env, proxy)
          result = {}
          env.each do |key, value|
            next unless key =~ /^HTTP_/

            key = headerize(key)
            if !key.eql? "Version"
              result[key] = value
            end
          end

          # Rack documentation says CONTENT_TYPE and CONTENT_LENGTH aren't prefixed by HTTP_
          result['Content-Type'] = env['CONTENT_TYPE'] if env['CONTENT_TYPE']

          length = env['CONTENT_LENGTH']
          result['Content-Length'] = length if length

          # added 4/23/09 per Charles Jolley, corrects problem
          # when making requests to virtual hosts
          result['Host'] = proxy[:to]

          result
        end

        # construct and display specific response headers
        def response_headers(hash)
          result = {}

          hash.each do |key, value|
            key = headerize(key)

            # Because Set-Cookie header can appear more the once in the response body,
            # but Rack only accepts a hash of headers, we store it in a line break separated string
            # for Ruby 1.9 and as an Array for Ruby 1.8
            # See http://groups.google.com/group/rack-devel/browse_thread/thread/e8759b91a82c5a10/a8dbd4574fe97d69?#a8dbd4574fe97d69
            if key.downcase == 'set-cookie'
              cookies = []

              case value
                when Array then value.each { |c| cookies << strip_domain(c) }
                when Hash  then value.each { |_, c| cookies << strip_domain(c) }
                else            cookies << strip_domain(value)
              end

              # Remove nil values
              result['Set-Cookie'] = [result['Set-Cookie'], cookies].compact

              if Thin.ruby_18?
                result['Set-Cookie'].flatten!
              else
                result['Set-Cookie'] = result['Set-Cookie'].join("\n")
              end
            end

            SC.logger << "   #{key}: #{value}\n"
            result[key] = value
          end

          ::Rack::Utils::HeaderHash.new(result)
        end

        # remove HTTP_, dasherize and titleize
        def headerize(str)
          parts = str.gsub(/^HTTP_/, '').split('_')
          parts.map! { |p| p.capitalize }.join('-')
        end

        # Strip out the domain of passed in cookie.  This technically may
        # break certain scenarios where services try to set cross-domain
        # cookies, but those services should not be doing that anyway...
        def strip_domain(cookie)
          cookie.to_s.gsub!(/domain=[^\;]+\;? ?/,'')
        end
      end
    end
  end

end
