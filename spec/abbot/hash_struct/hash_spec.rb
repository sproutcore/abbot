require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::HashStruct, 'hash operations' do
  
  include Abbot::SpecHelpers

  it "should allow arbitrary keys to be set/read using hash methods" do
    e = Abbot::HashStruct.new
    e[:foo] = :bar
    e[:foo].should eql(:bar)
  end
  
  it "should set any hash options passed to new" do
    e = Abbot::HashStruct.new :foo => :bar
    e[:foo].should eql(:bar)
  end
  
  it "should read any missing methods from the hash" do
    e = Abbot::HashStruct.new :foo => :bar
    e.foo.should eql(:bar)
  end
  
  it "should write missing methods ending in = to the hash" do
    e = Abbot::HashStruct.new 
    e.foo = :bar
    e[:foo].should eql(:bar)
  end
  
  it "should treat string and hash keys as the same" do
    e = Abbot::HashStruct.new
    e['foo'] = :bar
    e[:foo].should eql(:bar)
    
    e[:foo2] = :bar
    e['foo2'].should eql(:bar)
  end
  
  it "should convert all keys to symbols (i.e. if you get keys, they will always be symbols)" do
    e = Abbot::HashStruct.new
    e['string'] = :foo
    e[:symbol] = :foo
        
    expected = [:string, :symbol]
    idx=0
    e.keys.sort { |a,b| a.to_s <=> b.to_s }.each do |k|
      k.should eql(expected[idx])
      idx += 1
    end
  end
  
  it "should raise error if key cannot be converted to symbol" do
    a = Abbot::HashStruct.new
    
    # numbers respond to to_sym but return nil
    lambda { a[1] = :foo }.should raise_error
    lambda { a[1] }.should raise_error
    
    # Object does not respond to to_sym
    lambda { a[Object.new] = :foo }.should raise_error
    lambda { a[Object.new] }.should raise_error
  end
    
  
end
