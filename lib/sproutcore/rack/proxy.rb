module SC
  module Rack
    
    # Rack application proxies requests as needed for the given project.
    class Proxy
      
      def initialize(project)
        @project = project
      end
      
      def call(env)
      end
    end
  end
end