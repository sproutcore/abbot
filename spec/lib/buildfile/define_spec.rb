require "spec_helper"

describe SC::Buildfile, 'define' do

  it "should return new buildfile with task defined in block" do
    task_did_run = false
    b = SC::Buildfile.define do
      task :test_task do
        task_did_run = true
      end
    end

    b.should_not be_nil

    b.invoke :test_task
    task_did_run.should be_true
  end

  it "should inherit tasks defined by parent buildfile" do
    task1_did_run = false
    task2_did_run = false

    a = SC::Buildfile.define do
      task :test_task1 do
        task1_did_run = true
      end
    end

    b = a.dup.define! do
      task :test_task2 => :test_task1 do
        task2_did_run = true
      end
    end

    a.should_not be_nil
    b.should_not be_nil

    b.invoke :test_task2
    task1_did_run.should be_true
    task2_did_run.should be_true
  end

  it "should eval a string if passed to instance version" do

    # add accessor to test.
    a = SC::Buildfile.new.define! do
      def did_run; @did_run; end
    end

    # now try string eval...
    a.define! "task :test_task1 do\n@did_run = true\nend"

    a.invoke :test_task1
    a.did_run.should be_true
  end

end


