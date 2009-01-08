require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

# The config helper can be used in a Buildfile to specify config options
# targeted at specific bundle names.
#
# -- Note that we use the Buildfile.define() method to prepare these tests
# but you can also use these in Buildfiles using the Buildfile.load() method.
# The tests for those two method ensure that both approaches are identical.
#
describe Abbot::Buildfile::Commands, 'config' do
  
  it "should add the named config to the default mode when first defined" do
    a = Abbot::Buildfile.define do 
      config :test1, :foo => :bar
    end
    
    configs = a.configs
    
    configs.all.test1.should_not be_nil
    configs.all.test1.foo.should eql(:bar)
  end
  
  it "should merge options when same config is named mode than once" do
    a = Abbot::Buildfile.define do
      config :test1, :test1 => :foo, :test2 => :foo
      config :test1, :test1 => :bar
    end
    
    configs = a.configs
    configs.all.test1.test1.should eql(:bar)
    configs.all.test1.test2.should eql(:foo)
  end
  
  it "should both accept an options hash, accept a block, or both" do
    a = Abbot::Buildfile.define do
      config :test1, :foo => :bar
    end
    
    b = Abbot::Buildfile.define do
      config :test1 do |c|
        c[:foo] = :bar
      end
    end
    
    c = Abbot::Buildfile.define do
      config :test1, :test1 => :foo, :test2 => :foo do |c|
        c[:test1] = :bar
      end
    end
    
    a.configs.all.test1.foo.should eql(:bar)
    b.configs.all.test1.foo.should eql(:bar)
    c.configs.all.test1.test1.should eql(:bar)
    c.configs.all.test1.test2.should eql(:foo)
  end
  
  it "should allow OpenStruct-style setting of configs when passed to block" do
    a = Abbot::Buildfile.define do
      config :test1 do |c|
        c.foo = :bar
      end
    end  
    a.configs.all.test1.foo.should eql(:bar)
  end  
  
  it "should merge configs on top of a base buildfile configs without changing the root config" do
    a = Abbot::Buildfile.define do
      config :bundle, :test1 => :foo, :test2 => :foo
    end
    
    b = a.dup.define! do
      config :bundle, :test1 => :bar
    end
    
    b.configs.all.bundle.test1.should eql(:bar)
    b.configs.all.bundle.test2.should eql(:foo)
    
    a.configs.all.bundle.test1.should eql(:foo)
    a.configs.all.bundle.test2.should eql(:foo)
  end   
  
  it "should store configs inside of a specific mode when specified" do
    a = Abbot::Buildfile.define do
      mode :debug do
        config :bundle, :foo => :foo
      end
      config :bundle, :bar => :bar
    end
    
    a.configs.all.bundle.bar.should eql(:bar)
    a.configs.all.bundle.foo.should be_nil
    
    a.configs.debug.bundle.bar.should be_nil
    a.configs.debug.bundle.foo.should eql(:foo)
  end
  
end
