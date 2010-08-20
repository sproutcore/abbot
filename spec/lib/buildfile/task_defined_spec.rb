require "spec_helper"

describe SC::Buildfile, 'task_defined?' do

  it "should return true if the named task is defined" do
    b = SC::Buildfile.new
    b.define_task SC::Buildfile::Task, :test
    b.task_defined?(:test).should be_true
  end

  it "should return false if the named task is not defined" do
    b = SC::Buildfile.new
    b.task_defined?(:test).should be_false
  end

end

