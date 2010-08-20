require "spec_helper"

describe SC::Tools, 'build-number' do
  
  include SC::SpecHelpers
  
  before do 
    save_env
    SC.build_mode = :production
    @tool = SC::Tools.new('build_number')
  end
  
  after do
    restore_env
  end
  
  it "should raise error if no target is passed" do
    lambda { @tool.build_number }.should raise_error
  end
  
  it "should raise error if more than one target is passed" do
    lambda { @tool.build_number('target1','target2') }.should raise_error
  end
  
  it "should write build number when passed target" do
    expected_target = fixture_project(:real_world).target_for(:sproutcore)
    expected = expected_target.prepare!.compute_build_number

    @tool.set_test_project fixture_project(:real_world) # req...
    bn = capture('stdout') { @tool.build_number('sproutcore') }

    bn.should eql(expected)
  end
  
end
