require "spec_helper"

describe SC::ManifestEntry, 'prepare!' do
  
  include SC::SpecHelpers
  
  before do
    @project = fixture_project(:real_world)
    @target = @project.target_for :contacts
    
    @target.buildfile.define! do
      replace_task 'entry:prepare' do
        ENTRY.task_did_run = (ENTRY.task_did_run || 0) + 1
      end
    end
    
    @manifest = @target.manifest_for(:language => :en)
    
    # create entry manually to avoid calling prepare
    @entry = SC::ManifestEntry.new(@manifest, :filename => "filename")
  end

  it "should return self" do
    @entry.prepare!.should eql(@entry)
  end
  
  it "should execute entry:prepare if defined" do
    @entry.prepared?.should be_false # check precondition
    @entry.prepare!
    @entry.prepared?.should be_true
    @entry.task_did_run.should eql(1) # ran?
  end

  it "should do nothing if entry:prepare is not defined" do

    # get an empty project with no build tasks...
    project = empty_project
    project.add_target '/default', :default, :source_root => project.project_root
    target = project.targets['/default']
    target.buildfile.lookup('entry:prepare').should be_nil
    manifest = target.manifest_for :language => :en
    entry = SC::ManifestEntry.new(manifest, :filename => 'filename')
    lambda { entry.prepare! }.should_not raise_error
    
  end
  
  it "should execute entry:prepare only once" do
    @entry.prepared?.should be_false # check precondition
    @entry.prepare!.prepare!.prepare!
    @entry.prepared?.should be_true
    @entry.task_did_run.should eql(1) # ran only once?
  end
  
end
