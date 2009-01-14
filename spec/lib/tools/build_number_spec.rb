require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Tools, 'build-number' do
  
  include SC::SpecHelpers
  
  before do 
    @tool = SC::Tools.new('build_number')
  end
  
  it "should raise error if no target is passed" do
    lambda { @tool.build_number }.should raise_error
  end
  
  it "should raise error if more than one target is passed" do
    lambda { @tool.build_number('target1','target2') }.should raise_error
  end
  
  it "should write build number when passed target" do
    @tool.project = fixture_project(:real_world) # req...
    bn = capture('stdout') { @tool.build_number('sproutcore') }
    
    expected_target = fixture_project(:real_world).target_for(:sproutcore)
    expected = expected_target.prepare!.compute_build_number
    bn.should eql(expected)
  end
  
end
