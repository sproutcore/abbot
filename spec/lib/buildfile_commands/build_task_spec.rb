require "spec_helper"

describe SC::Buildfile::Commands, 'build_task' do

  it "should add a new task to the buildfile" do
    b = SC::Buildfile.define do
      build_task :task1
    end
    b.task_defined?(:task1).should_not be_nil
  end

  it "should add a new task with class BuildTask" do
    b = SC::Buildfile.define do
      build_task :task1
    end
    b.lookup(:task1).class.should eql(SC::Buildfile::BuildTask)
  end

end
