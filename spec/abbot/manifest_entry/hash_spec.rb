require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::ManifestEntry, 'hash operations' do
  
  include Abbot::SpecHelpers

  it "should allow arbitrary keys to be set/read using hash methods" do
    e = Abbot::ManifestEntry.new
    e[:foo] = :bar
    e[:foo].should eql(:bar)
  end
  
  it "should set any hash options passed to new" do
    e = Abbot::ManifestEntry.new :foo => :bar
    e[:foo].should eql(:bar)
  end
  
  it "should read any missing methods from the hash" do
    e = Abbot::ManifestEntry.new :foo => :bar
    e.foo.should eql(:bar)
  end
  
  it "should write missing methods ending in = to the hash" do
    e = Abbot::ManifestEntry.new 
    e.foo = :bar
    e[:foo].should eql(:bar)
  end
  
  it "should treat string and hash keys as the same" do
    e = Abbot::ManifestEntry.new
    e['foo'] = :bar
    e[:foo].should eql(:bar)
    
    e[:foo2] = :bar
    e['foo2'].should eql(:bar)
  end
  
end
