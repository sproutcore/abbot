require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Target, 'required_targets' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)
  end
    
  it "should resolve references to child targets" do
    target = @project.target_for :sproutcore
    
    # verify precondition 
    # -- the required property should NOT be array ...
    target.config.required.should eql(:desktop)
  
    expected = @project.target_for('sproutcore/desktop')
    
    target.required_targets.size.should eql(1)
    target.required_targets.first.should eql(expected)
  end
  
  it "should resolve references to siblings" do
    target = @project.target_for 'sproutcore/application'
  
    # verify precondition
    #  -- the required config should be an array
    target.config.required.size.should eql(2)
    
    expected = @project.target_for('sproutcore/costello')
    target.required_targets.size.should eql(2)
    target.required_targets.should include(expected)
  end
  
  it "should resolve references to other subtargets" do
    target = @project.target_for :mobile_photos
    target.required_targets.size.should eql(1)
    
    expected = @project.target_for('sproutcore/mobile')
    target.required_targets.first.should eql(expected)
  end
  
end
