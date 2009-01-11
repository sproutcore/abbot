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
  
  
  # Weird edge case -- if a global constant is already set with an equal
  # value, make sure it is overwritten and restored anyway.
  it "should overwrite & restore global constants regardles of value" do
    
    # create two object instances with the same "value"
    const1 = {}
    const2 = {}
    
    Kernel.const_reset(:CONSTANT, const1)
    buildfile.execute_task :task2, :constant => const2
    
    # now add some keys so we can tell them apart...
    const1[:foo] = :const1
    const2[:foo] = :const2
    
    CONSTANT[:foo].should eql(:const1)
    task_result[:foo].should eql(:const2)
  end
      
end