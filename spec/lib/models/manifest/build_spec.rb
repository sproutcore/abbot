require "spec_helper"

describe SC::Manifest, 'build!' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)

    ## IMPORTANT: Note the task defined here is assumed by tests below...
    @project.buildfile.define! do
      replace_task 'manifest:prepare' do
        # avoid invoking original machinery...
      end

      replace_task 'manifest:build' do
        MANIFEST.task_did_run = (MANIFEST.task_did_run || 0) + 1
      end

      replace_task 'entry:prepare' do
        # also avoid original machinery...
      end

    end

    @target = @project.target_for :contacts
    @manifest = @target.manifest_for(:language => :en)
  end

  it "should return self" do
    @manifest.build!.should eql(@manifest)
  end

  it "should call prepare! then call manifest:build if defined" do
    @manifest.prepared?.should be_false # check precondition
    @manifest.build!
    @manifest.prepared?.should be_true

    @manifest.task_did_run.should eql(1) # ran?
  end

  it "should do nothing manifest:build is not defined" do
    # get an empty project with no build tasks...
    project = empty_project
    project.add_target '/default', :default, :source_root => project.project_root
    target = project.targets[:'/default']
    target.buildfile.lookup('manifest:build').should be_nil

    manifest = target.manifest_for :language => :en
    lambda { manifest.build! }.should_not raise_error
  end

  it "should build only once unless reset_entries! is called" do
    @manifest.build! # do build once...
    @manifest.add_entry 'example'  # pretend this happpened during build...
    @manifest.entries.size.should eql(1) # precondition

    @manifest.build!
    @manifest.entries.size.should eql(1) # should NOT be reset.

    # reset and try again
    @manifest.reset_entries!
    @manifest.build!
    @manifest.entries.size.should eql(0) # should be reset.
     # build! would normally repopulate...

  end

  it "should execute manifest:build only one time unless reset" do
    @manifest.prepared?.should be_false # check precondition
    @manifest.build!.build! # second time should do nothing
    @manifest.reset_entries!
    @manifest.build! # should run since we reset...
    @manifest.prepared?.should be_true
    @manifest.task_did_run.should eql(2) # ran only once?
  end

end
