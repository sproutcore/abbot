require "spec_helper"

describe SC::Target, 'prepare!' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)

    # get target from project manually since target_for() calls prepare!
    @target = @project.targets[:'/contacts']

    @target.buildfile.define! do
      replace_task 'target:prepare' do
        TARGET.task_did_run = (TARGET.task_did_run || 0) + 1
      end
    end

  end

  it "should return self" do
    @target.prepare!.should eql(@target)
  end

  it "should execute target:prepare if defined" do
    @target.prepared?.should be_false # check precondition
    @target.prepare!
    @target.prepared?.should be_true
    @target.task_did_run.should eql(1) # ran?
  end

  it "should do nothing if target:prepare is not defined" do

    # get an empty project with no build tasks...
    project = empty_project
    project.add_target '/default', :default, :source_root => project.project_root
    target = project.targets[:'/default']
    target.buildfile.lookup('target:prepare').should be_nil

    lambda { target.prepare! }.should_not raise_error

  end

  it "should execute target:prepare only once" do
    @target.prepared?.should be_false # check precondition
    @target.prepare!.prepare!.prepare!
    @target.prepared?.should be_true
    @target.task_did_run.should eql(1) # ran only once?
  end

end


