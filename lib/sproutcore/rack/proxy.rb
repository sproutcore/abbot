module SC
  module Rack
    
    # Rack application proxies requests as needed for the given project.
    class Proxy
      
      def initialize(project)
        @project = project
      end
      
      def call(env)
        return [404, {}, "not found"]
      end
    end
  end
end