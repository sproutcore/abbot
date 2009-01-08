require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Buildfile::Commands, 'task' do

  it "should add a new task to the buildfile" do
    b = Abbot::Buildfile.define do
      task :task1 
    end
    b.task_defined?(:task1).should_not be_nil
  end
  
  it "should add a new task with a dependency if specified" do
    b = Abbot::Buildfile.define do
      task :task1 => :task2
    end
    b.lookup(:task1).prerequisites.first.should eql('task2')
  end

end
