require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::HashStruct, 'has_options?' do
  
  include SC::SpecHelpers

  before do 
    @hash = SC::HashStruct.new :foo => :foo, :bar => :bar
  end
  
  it "always returns true if passed match is empty or nil" do
    @hash.has_options?.should be_true
    @hash.has_options?({}).should be_true
  end
  
  it "returns true if every key/value pair in passed value set matches" do
    @hash.has_options?(:foo => :foo, :bar => :bar).should be_true
  end
  
  it "returns false if any key/value pair in passed value set does not match" do
    @hash.has_options?(:foo => :foo, :bar => :no_match).should be_false
  end
  
  it "returns false if any key/value pair does not exist in hash" do
    @hash.has_options?(:imaginary => true).should be_false
  end
  
  it "returns treats strings + symbols the same for keys" do
    @hash.has_options?('foo' => :foo, 'bar' => :bar).should be_true
  end
  
end