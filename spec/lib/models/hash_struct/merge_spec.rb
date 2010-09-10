require "spec_helper"

describe SC::HashStruct, 'merge!' do

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
