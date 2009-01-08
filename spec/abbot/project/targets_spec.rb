require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Project, 'targets' do

  include Abbot::SpecHelpers

  it "should invoke the abbot:find_targets task the first time you get targets" do
    
    did_invoke_task = false
    
    project = empty_project
    project.buildfile.define! do
      namespace :abbot do
        task :find_targets do
          did_invoke_task = YES
        end
      end
    end
    
    targets = project.targets
    did_invoke_task.should be_true
  end
  
  it "should silently skip if abbot:find_targets is not defined" do
    project = empty_project
    lambda { project.targets }.should_not raise_error
    project.targets.size.should eql(0)
  end
    
  it "should clone targets from a parent project" do
    parent = empty_project
    parent.buildfile.define! do
      namespace :abbot do
        task :find_targets do
          PROJECT.add_target :base1, :dummy_type
        end
      end
    end
    
    project = Abbot::Project.new fixture_path('buildfiles', 'empty_project'), :parent => parent
    project.targets.size.should eql(1)
    project.targets['base1'].target_name.should eql(:base1)
  end
    
end

