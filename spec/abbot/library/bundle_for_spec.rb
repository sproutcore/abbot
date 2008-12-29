require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Library, 'bundle_for' do
  
  include Abbot::SpecHelpers
  
  before do 
    @paths = [fixture_path, fixture_path('installed_library', 'lib')]
    @library_path = fixture_path('basic_library')
    @bundle = Abbot::Library.library_for @library_path, :paths => @paths
  end
  
  it "should find locally installed bundles by name" do
    b = @bundle.bundle_for(:app1)
    b.should_not be_nil
    b.source_root.should eql(fixture_path('basic_library', 'apps', 'app1'))    
  end
  
  it "should find local nested bundles (and take string param)" do
    p = fixture_path('basic_library', 'frameworks', 'lib1', 'apps', 'nested_app1')
    b = @bundle.bundle_for('lib1/nested_app1')
    b.should_not be_nil
    b.source_root.should eql(p)    
  end

  it "should find bundles installed from ENV:PATH" do
    p = fixture_path('installed_library', 'frameworks', 'installed_lib1')
    b = @bundle.bundle_for(:installed_lib1)
    b.should_not be_nil
    b.source_root.should eql(p)    
  end

  it "local bundles should override installed bundles" do
    p = fixture_path('basic_library', 'frameworks', 'lib1')
    b = @bundle.bundle_for(:lib1)
    b.should_not be_nil
    b.source_root.should eql(p)    
  end

  it "should find nested libs in ENV:PATH lib even if parent lib is also in installed lib" do
    p = fixture_path('installed_library', 'frameworks', 'lib1', 'frameworks', 'nested_lib2')
    b = @bundle.bundle_for('lib1/nested_lib2')
    b.should_not be_nil
    b.source_root.should eql(p)    
  end
    
end

    
