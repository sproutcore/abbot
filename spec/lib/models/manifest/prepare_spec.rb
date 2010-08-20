require "spec_helper"

describe SC::Manifest, 'prepare!' do
  
  include SC::SpecHelpers
  
  before do
    @project = fixture_project(:real_world)
    @target = @project.target_for :contacts
    
    @target.buildfile.define! do
      
      replace_task 'target:prepare' do
        # avoid invoking original machinery...
      end
      
      replace_task 'manifest:prepare' do
        MANIFEST.task_did_run = (MANIFEST.task_did_run || 0) + 1
      end
    end
    
    @manifest = @target.manifest_for(:language => :en)
  end

  it "should return self" do
    @manifest.prepare!.should eql(@manifest)
  end

  it "should execure prepare! on target" do
    @target.prepared?.should be_false
    @manifest.prepare!
    @target.prepared?.should be_true
  end
  
  it "should execute manifest:prepare if defined" do
    @manifest.prepared?.should be_false # check precondition
    @manifest.prepare!
    @manifest.prepared?.should be_true
    @manifest.task_did_run.should eql(1) # ran?
  end

  it "should do nothing if manifest:prepare is not defined" do

    # get an empty project with no build tasks...
    project = empty_project
    project.add_target '/default', :default, :source_root => project.project_root
    target = project.targets['/default']
    target.buildfile.lookup('manifest:prepare').should be_nil
    
    manifest = target.manifest_for :language => :en
    lambda { manifest.prepare! }.should_not raise_error
    
  end
  
  it "should execute manifest:prepare only once" do
    @manifest.prepared?.should be_false # check precondition
    @manifest.prepare!.prepare!.prepare!
    @manifest.prepared?.should be_true
    @manifest.task_did_run.should eql(1) # ran only once?
  end
  
end
