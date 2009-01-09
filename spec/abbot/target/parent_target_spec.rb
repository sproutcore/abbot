require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Target, 'parent_target' do

  include Abbot::SpecHelpers

  before do
    @project = real_world_project
  end

  it "should return next direct parent when nested" do
    target = @project.target_for('sproutcore/costello')
    target.parent_target.should eql(@project.target_for(:sproutcore))
  end
  
  it "should return project if top-level" do
    target = @project.target_for(:sproutcore)
    target.parent_target.should eql(@project)
  end
    
end
