require "spec_helper"

describe SC::HashStruct, 'merge!' do

  it "should convert all keys to symbols - if symbol and string is passed, they will overrwite" do
    a = SC::HashStruct.new
    a.merge! :foo => :bar1, 'foo' => :bar2
    a.keys.size.should eql(1)
    a.keys.first.should eql(:foo)
  end

  it "should do nothing if we merge self!" do
    a = SC::HashStruct.new :foo => :bar
    a.merge! a
    a[:foo].should eql(:bar)
    a.keys.size.should eql(1)
  end

  it "should do nothing if we merge nil" do
    a = SC::HashStruct.new :foo => :bar
    lambda { a.merge! nil }.should_not raise_error
    a[:foo].should eql(:bar)
    a.keys.size.should eql(1)
  end

end
