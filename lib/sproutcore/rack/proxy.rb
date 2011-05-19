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

require 'eventmachine'
require 'em-http'

module SC
  module Rack

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

      def handle_proxy(proxy, proxy_url, env)

        if proxy[:secure] && !SC::HTTPS_ENABLED
          SC.logger << "~ WARNING: HTTPS is not supported on your system, using HTTP instead.\n"
          SC.logger << "    If you are using Ubuntu, you can run `apt-get install libopenssl-ruby`\n"
          proxy[:secure] = false
        end

        method = env['REQUEST_METHOD'].to_s.downcase  # ex. get
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

        # Add the body for methods that accept it but only if Content-Length > 0
        unless %w(get copy head move options trace).include?(method)
          body = env['rack.input']
          body.rewind # May not be necessary but can't hurt

          http_body = body.read if headers['Content-Length'].to_i > 0 #request_options[:body]
        end

        # Options for the request
        request_options = { :head => headers }
        request_options[:body] = http_body if http_body
        request_options[:timeout] = proxy[:timeout] if proxy[:timeout]
        request_options[:redirects] = 10 if proxy[:redirect] != false

        EventMachine.run {
          case method
            when 'get'
              http = EventMachine::HttpRequest.new(url).get request_options
            when 'post'
              http = EventMachine::HttpRequest.new(url).post request_options
            when 'put'
              http = EventMachine::HttpRequest.new(url).put request_options
            when 'delete'
              http = EventMachine::HttpRequest.new(url).delete request_options
            else
              http = EventMachine::HttpRequest.new(url).head request_options
            end

          # Received error
          http.errback {
            response_status = http.response_header.status

            # TODO: Might be able to provide better error handling here
            SC.logger << "~ !!ERROR!! PROXY: #{method.upcase} #{response_status} #{path} -> #{uri}\n"
          }

          # Received response
          http.callback {
            status = http.response_header.status

            SC.logger << "~ PROXY: #{method.upcase} #{status} #{path} -> #{http.last_effective_url}\n"

            headers = response_headers(proxy, http.response_header)

            # Thin doesn't like null bodies
            body = http.response || ''

            env["async.callback"].call [status, headers, [body]]
          }
        }
      end

      # collect headers...
      def request_headers(env, proxy)
        result = {}
        env.each do |key, value|
          next unless key =~ /^HTTP_/

          # remove HTTP_, dasherize and titleize
          key = key.gsub(/^HTTP_/,'').downcase.sub(/^\w/){|l| l.upcase}.gsub(/_(\w)/){|l| "-#{$1.upcase}"}
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
      def response_headers(proxy, headers)
        result = {}
        ignore_headers = ['transfer-encoding', 'keep-alive', 'connection']
        http_host, http_port = proxy[:to].split(':')

        headers.each do |key, value|
          key = key.downcase.sub(/^\w/){|l| l.upcase}.gsub(/_(\w)/){|l| "-#{$1.upcase}"} # remove HTTP_, dasherize and titleize
          next if ignore_headers.include?(key.downcase)

          # Location headers should rewrite the hostname if it is included.
          value.gsub!(/^http:\/\/#{http_host}(:[0-9]+)?\//, "http://#{http_host}/") if key.downcase == 'location'

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


      # Strip out the domain of passed in cookie.  This technically may
      # break certain scenarios where services try to set cross-domain
      # cookies, but those services should not be doing that anyway...
      def strip_domain(cookie)
        cookie.to_s.gsub!(/domain=[^\;]+\;? ?/,'')
      end
    end
  end
end
