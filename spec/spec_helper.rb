require 'fileutils'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib abbot]))

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

module Abbot
  
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
      Abbot::Project.new fixture_path('buildfiles', 'empty_project')
    end
        
    def basic_library_path
      fixture_path('basic_libary')
    end
    
    
    ################################
    
    # Gets the abbot project itself as a library.  Useful for testing builtin
    # options.
    def abbot_library
      Abbot::Library.library_for fixture_path('..','..'), :paths => []
    end
    
    # Gets a new Library with the basic library as the root + 
    # installed_library in the path.  vs. basic_library_bundle which gets 
    # a bundle...
    def basic_library 
      Abbot::Library.library_for fixture_path('basic_library'),
        :paths => [fixture_path('installed_library'), fixture_path('..','..')]
    end
    
    def basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library')
    end
    
    def app1_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'apps', 'app1'), :bundle_type => :app, :parent_bundle => parent_bundle
    end

    def client1_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'clients', 'client1'), :bundle_type => :app, :parent_bundle => parent_bundle
    end

    def lib1_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'frameworks', 'lib1'), :bundle_type => :framework, :parent_bundle => parent_bundle
    end

    def lib2_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'frameworks', 'lib2'), :bundle_type => :framework, :parent_bundle => parent_bundle
    end

    def nested_lib1_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'frameworks', 'lib1', 'frameworks', 'nested_lib1'), :bundle_type => :framework, :parent_bundle => lib1_bundle
    end

    def nested_app1_bundle(parent_bundle=nil)
      parent_bundle ||= basic_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('basic_library', 'frameworks', 'lib1', 'apps', 'nested_app1'), :bundle_type => :app, :parent_bundle => lib1_bundle
    end
    
    def installed_library_bundle
      Abbot::Bundle.new :source_root => fixture_path('installed_library')
    end
      
  end
end

# EOF
