module SC
  module Rack

    # Rewrites relevant requests to load the SproutCore test runner for a 
    # given project.
    class TestRunner
      
      def initialize(project)
        @project = project
      end
      
      def call(env)
      end
    end
  end
end