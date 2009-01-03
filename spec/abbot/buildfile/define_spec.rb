require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Buildfile, 'define' do

  it "should return new buildfile with task defined in block" do
    task_did_run = false
    b = Abbot::Buildfile.define do 
      task :test_task do
        task_did_run = true
      end
    end
    
    b.should_not be_nil
    
    b.execute_task :test_task
    task_did_run.should be_true
  end
  
  it "should inherit tasks defined by parent buildfile" do
    task1_did_run = false
    task2_did_run = false
    
    a = Abbot::Buildfile.define do
      task :test_task1 do
        task1_did_run = true
      end
    end
    
    b = Abbot::Buildfile.define(a) do
      task :test_task2 => :test_task1 do
        task2_did_run = true
      end
    end
    
    a.should_not be_nil
    b.should_not be_nil
    
    b.execute_task :test_task2
    task1_did_run.should be_true
    task2_did_run.should be_true
  end
end

        
