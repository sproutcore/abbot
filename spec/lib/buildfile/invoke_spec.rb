require "spec_helper"

buildfile = nil
task_result = nil

describe SC::Buildfile, 'invoke' do

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
    buildfile.invoke :task1
    task_result.should eql(:task1)
    
    task_result = nil
    buildfile.invoke :task1
    task_result.should eql(:task1)
  end
  
  it "should set any constants passed in to second option" do
    task_result = nil
    buildfile.invoke :task2, :constant => :test1
    task_result.should eql(:test1)

    task_result = nil
    buildfile.invoke :task2, :constant => :test2
    task_result.should eql(:test2)
  end
  
  
  # Weird edge case -- if a global constant is already set with an equal
  # value, make sure it is overwritten and restored anyway.
  it "should overwrite & restore global constants regardles of value" do
    
    # create two object instances with the same "value"
    const1 = {}
    const2 = {}
    
    Kernel.const_reset(:CONSTANT, const1)
    buildfile.invoke :task2, :constant => const2
    
    # now add some keys so we can tell them apart...
    const1[:foo] = :const1
    const2[:foo] = :const2
    
    CONSTANT[:foo].should eql(:const1)
    task_result[:foo].should eql(:const2)
  end
  
  describe "prerequisites" do
    
    it "should invoke each prerequisite only once" do
      results = {}
      buildfile = SC::Buildfile.define do
        
        task :a do
          RESULTS[:a] = (RESULTS[:a] || 0) + 1
        end
        
        task :b => :a do
          RESULTS[:b] = (RESULTS[:b] || 0) + 1
        end
        
        task :c => [:a, :b] do
          RESULTS[:c] = (RESULTS[:c] || 0) + 1
        end
      end
      
      buildfile.invoke :c, :results => results
      
      # task :A should have executed only once even though it is a pre-req
      # of both b & c
      results[:a].should eql(1)
      results[:b].should == 1
      results[:c].should == 1
    end
    
    it "should keep track of prereqs separately for each call to execute" do
      results = {}
      buildfile = SC::Buildfile.define do
        
        task :a do
          RESULTS[:a] = (RESULTS[:a] || 0) + 1

          # Recursive call.  Note that in regular Rake, this will reset the
          # invocation chain and :a will get called too many times...
          BUILDFILE.invoke :d

        end
        
        task :b => :a do
          RESULTS[:b] = (RESULTS[:b] || 0) + 1
        end
        
        task :c => [:a, :b] do
          RESULTS[:c] = (RESULTS[:c] || 0) + 1
        end

        task :d do
          RESULTS[:d] = (RESULTS[:d] || 0) + 1
        end
        
      end
      
      buildfile.invoke :c, :results => results, :buildfile => buildfile

      # task :a should have executed twice because invoke() was invoked
      # twice (once from within task :d)
      results[:a].should eql(1)
      results[:b].should == 1
      results[:c].should == 1
    end
        
  end
      
end
