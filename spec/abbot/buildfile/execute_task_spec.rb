require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

buildfile = nil
task_result = nil

describe SC::Buildfile, 'execute_task' do

  include SC::SpecHelpers

  before do
    buildfile = SC::Buildfile.define do 
      
      task :task1 do
        task_result = :task1
      end
      
      task :task2 do
        task_result = CONSTANT
      end
    end
  end
  
  it "should execute a task everytime it is called; even if task has run" do
    task_result = nil
    buildfile.execute_task :task1
    task_result.should eql(:task1)
    
    task_result = nil
    buildfile.execute_task :task1
    task_result.should eql(:task1)
  end
  
  it "should set any constants passed in to second option" do
    task_result = nil
    buildfile.execute_task :task2, :constant => :test1
    task_result.should eql(:test1)

    task_result = nil
    buildfile.execute_task :task2, :constant => :test2
    task_result.should eql(:test2)
  end
    
end