require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Buildfile::Commands, 'task' do

  it "should add a new task to the buildfile" do
    b = SC::Buildfile.define do
      task :task1 
    end
    b.task_defined?(:task1).should_not be_nil
  end
  
  it "should add a new task with a dependency if specified" do
    b = SC::Buildfile.define do
      task :task1 => :task2
    end
    b.lookup(:task1).prerequisites.first.should eql('task2')
  end
  
  it "extend an existing task by adding the second action if defined" do
    results = {}
    b = SC::Buildfile.define do
      task :task1 do
        RESULTS[:foo] = true
      end
      
      task :task1 do
        RESULTS[:bar] = true
      end
    end
    
    b.invoke :task1, :results => results
    results[:foo].should be_true
    results[:bar].should be_true
  end

end
