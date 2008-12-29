require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Library, 'library_for' do
  include Abbot::SpecHelpers
  
  it "should automatically create bundles for target bundle and those in load path" do
    paths = [fixture_path, fixture_path('installed_library', 'lib')]
    lib_path = fixture_path('basic_library')
    
    # Check returned bundle
    b = Abbot::Library.library_for lib_path, :paths => paths
    b.source_root.should eql(lib_path)
    
    # Check next_library
    (b = b.next_library).should_not be_nil
    b.source_root.should eql(fixture_path('installed_library'))
    
    # Should be it
    b.next_library.should be_nil
  end
end
