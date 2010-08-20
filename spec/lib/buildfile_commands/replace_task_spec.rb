require "spec_helper"

describe SC::Buildfile::Commands, 'task' do

  it "should add a new task to the buildfile" do
    b = SC::Buildfile.define do
      replace_task :task1
    end
    b.task_defined?(:task1).should_not be_nil
  end

  it "should replace an existing task completely if defined" do
    results = {}
    b = SC::Buildfile.define do
      task :task1 do
        RESULTS[:foo] = :original
      end

      replace_task :task1 do
        RESULTS[:foo] = :replaced
      end
    end

    b.invoke :task1, :results => results

    results[:foo].should eql(:replaced)
  end

end
