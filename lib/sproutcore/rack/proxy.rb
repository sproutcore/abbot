require 'net/http'
module SC
  module Rack 
     
    # Rack application proxies requests as needed for the given project. 
    class Proxy 
       
      def initialize(project) 
        @project = project
        @proxies = project.buildfile.proxies
      end 
       
      def call(env)        
        url = env['PATH_INFO']
        
        @proxies.each do |proxy, value|
          if url.match(proxy.to_s)
            return handle_proxy(value, proxy.to_s, env)
          end
        end
        
        return [404, {}, "not found"]
      end
      
      def handle_proxy(proxy, proxy_url, env)  
        origin_host = env['SERVER_NAME'] # capture the origin host for cookies
        http_method = env['REQUEST_METHOD'].to_s.downcase
        url = env['PATH_INFO']
        params = env['QUERY_STRING']
                
        # collect headers...
        headers = {}
        env.each do |key, value|
          next unless key =~ /^HTTP_/
          key = key.gsub(/^HTTP_/,'')
          headers[key] = value
        end
        
        http_host = proxy[:to].split(':').first()
        http_port = proxy[:to].split(':').last()
        # proxy_url.gsub!(/([\/|\~])/) { |e| '\\' << e } # TODO: escape any / or ~ in proxy_url what else should be escaped?
        # TODO: how do I replace part of url with proxy_url?
        http_path = url.delete('~')
        http_path << '?' << params if params.size > 0
         
        response = nil
        no_body_method = %w(delete get copy head move options trace) 
        ::Net::HTTP.start(http_host, http_port) do |http|
          if no_body_method.include?(http_method)
            response = http.send(http_method, http_path, headers)
          else
            # TODO: Where is the Rack env body?
            # http_body = request.raw_post
            # puts env.to_yaml
            # response = http.send(http_method, http_path, http_body, headers)
          end
        end
        
        return [404, {}, "not found"] if response.nil?
         
        status = response.code # http status code
        
        SC.logger << "~ PROXY: #{status} #{url} -> http://#{http_host}:#{http_port}#{http_path}\n"
        
        # display and construct specific response headers
        response_headers = {}
        ignore_headers = ['transfer-encodeing', 'keep-alive', 'connection'] 
        response.each do |key, value|
          next if ignore_headers.include?(key.downcase)
          # If this is a cookie, strip out the domain.  This technically may
          # break certain scenarios where services try to set cross-domain
          # cookies, but those services should not be doing that anyway...
          value.gsub!(/domain=[^\;]+\;? ?/,'') if key.downcase == 'set-cookie'
          # Location headers should rewrite the hostname if it is included.
          value.gsub!(/^http:\/\/#{http_host}(:[0-9]+)?\//, "http://#{request.host}/") if key.downcase == 'location'
          
          SC.logger << "   #{key}: #{value}\n"
          response_headers[key] = value
        end
        
        return [status, ::Rack::Utils::HeaderHash.new(response_headers), [response.body]]
      end 
    end 
  end 
end