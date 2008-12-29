require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Library, 'bundle_paths_from' do
  
  include Abbot::SpecHelpers
  
  it "should automatically detect bundles in a load path" do
    paths = [fixture_path, fixture_path('basic_library'), fixture_path('installed_library', 'lib')]
    paths = Abbot::Library.bundle_paths_from(paths)
    paths.size.should eql(2)
    paths.should include(fixture_path('basic_library'), fixture_path('installed_library'))
  end
    
end

