require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

# define a custom subclass of the task to make sure classes are copied
class CustomTestTask < SC::Buildfile::Task  
  attr_accessor :test_property
end

describe SC::Buildfile, 'dup' do

  it "should clone tasks so that the new tasks belong to the new buildfile" do
    a = SC::Buildfile.define do
      task :foo 
    end
    
    b = a.dup
    
    a.lookup(:foo).application.should eql(a)
    b.lookup(:foo).application.should eql(b)
  end
  
  it "should clone tasks, including any custom subclasses" do
    a = SC::Buildfile.define do
      t = define_task CustomTestTask, :foo
      t.test_property = :bar
    end
    
    b = a.dup
    
    a.lookup(:foo).class.should eql(CustomTestTask)
    a.lookup(:foo).test_property.should eql(:bar)
    
    b.lookup(:foo).class.should eql(CustomTestTask)
    b.lookup(:foo).test_property.should eql(:bar)
  end
  
  it "should clone config" do
    a = SC::Buildfile.define do
      config :all, :foo => :foo
    end
    
    b = a.dup.define! do
      config :all, :foo => :bar
    end
    
    a.configs.all.all.foo.should eql(:foo)
    b.configs.all.all.foo.should eql(:bar)
  end
  
  it "should clone project_type" do
    a = SC::Buildfile.define
    a.project_type = :foo
    
    a.dup.project_type.should eql(:foo)
  end
  
  it "should NOT clone the project? status (must be set per-instance)" do
    a = SC::Buildfile.define
    a.project!
    a.project?.should be_true
    
    a.dup.project?.should be_false
  end
  
  
end