
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
    
    def basic_library_path
      fixture_path('basic_libary')
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
