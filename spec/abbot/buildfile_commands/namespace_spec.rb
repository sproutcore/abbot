require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Buildfile::Commands, 'namespace' do

  it "should define tasks as part of namespace" do
    b = Abbot::Buildfile.define do
      namespace :foo do
        task :task1 
      end
      
      task :task2
    end
    b.task_defined?('foo:task1').should be_true
    b.task_defined?(:task2).should be_true
    b.task_defined?('foo:task2').should be_false
  end

end
