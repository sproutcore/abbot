require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Buildfile, 'task_defined?' do

  it "should return true if the named task is defined" do
    b = Abbot::Buildfile.new
    b.define_task ::Rake::Task, :test  
    b.task_defined?(:test).should be_true
  end

  it "should return false if the named task is not defined" do
    b = Abbot::Buildfile.new
    b.task_defined?(:test).should be_false
  end

end
  