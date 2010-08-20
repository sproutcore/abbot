require "spec_helper"

describe SC::Target, 'parent_target' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)
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
