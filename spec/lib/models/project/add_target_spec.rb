require "spec_helper"

describe SC::Project, 'add_target' do

  include SC::SpecHelpers

  before do
    @project = SC::Project.new fixture_path('buildfiles', 'empty_project')
  end

  it "should add a target with the passed name" do
    @project.add_target :target_name, :target_type
    target = @project.targets[:target_name]
    target.should_not be_nil
    target.target_name.should eql(:target_name)
    target.target_type.should eql(:target_type)
  end

  it "should set the target.project automatically" do
    @project.add_target :target_name, :target_type
    @project.targets[:target_name].project.should eql(@project)
  end

  it "should set any other passed options on the target itself" do
    @project.add_target :target_name, :target_type, :foo => :foo, :bar => :bar
    target = @project.targets[:target_name]

    target.should_not be_nil
    target.foo.should eql(:foo)
    target.bar.should eql(:bar)
  end

  it "should replace an existing target if defined" do
    @project.add_target :test1, :dummy
    target1 = @project.targets[:test1]

    @project.add_target :test1, :dummy2
    target2 = @project.targets[:test1]

    target2.should_not eql(target1)
    target2.target_type.should eql(:dummy2)
  end

end
