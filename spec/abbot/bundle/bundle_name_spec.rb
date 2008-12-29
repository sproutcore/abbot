require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'bundle_name' do
  
  include Abbot::SpecHelpers

  it "should be nil for library" do
    basic_library_bundle.bundle_name.should be_nil
  end
  
  it "should be the bundle basename as sym when directly under library" do
    app1_bundle.bundle_name.should eql(:app1)
    client1_bundle.bundle_name.should eql(:client1)
    lib1_bundle.bundle_name.should eql(:lib1)
  end 
  
  it "should be parent bundle_name/bundle basename as sym when nested" do
    nested_lib1_bundle.bundle_name.should eql(:'lib1/nested_lib1')
    nested_app1_bundle.bundle_name.should eql(:'lib1/nested_app1')
  end

end
