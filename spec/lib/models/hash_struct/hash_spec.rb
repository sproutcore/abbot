require "spec_helper"

describe SC::HashStruct, 'hash operations' do

  include SC::SpecHelpers

  it "should allow arbitrary keys to be set/read using hash methods" do
    e = SC::HashStruct.new
    e[:foo] = :bar
    e[:foo].should eql(:bar)
  end

  it "should set any hash options passed to new" do
    e = SC::HashStruct.new :foo => :bar
    e[:foo].should eql(:bar)
  end

  it "should read any missing methods from the hash" do
    e = SC::HashStruct.new :foo => :bar
    e.foo.should eql(:bar)
  end

  it "should write missing methods ending in = to the hash" do
    e = SC::HashStruct.new
    e.foo = :bar
    e[:foo].should eql(:bar)
  end

end
