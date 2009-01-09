require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Buildfile::Commands, 'namespace' do

  it "should define tasks as part of namespace" do
    b = SC::Buildfile.define do
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
