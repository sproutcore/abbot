require 'fileutils'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib sproutcore]))

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

module SC
  
  module SpecHelpers
    
    def fixture_path(*path_items)
      (path_items = path_items.flatten).unshift 'fixtures'
      File.expand_path File.join(File.dirname(__FILE__), path_items)
    end
    
    # Make the a newer than b.  touch then sleep until it works...
    def make_newer(path_a, path_b)
      FileUtils.touch(path_a)
      while File.mtime(path_a) <= File.mtime(path_b)
        sleep(0.1)
        FileUtils.touch(path_a)
      end
    end

    def empty_project
      SC::Project.new fixture_path('buildfiles', 'empty_project')
    end
    
    # The builtin project (i.e. default Buildfile)
    def builtin_project
      SC::Project.new fixture_path('..','..')
    end
    
    # Loads a standard project, with the builtin project as parent.  Simulates
    # real world scenario
    def real_world_project
      SC::Project.new fixture_path('real_world'), :parent => builtin_project
    end
    
  end
end

# EOF
