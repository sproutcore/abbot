require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::HashStruct, 'method_missing' do

  before do
    hash = SC::HashStruct.new :foo => :foo
  end
  
  it "should map hash.foo => hash[:foo]" do
    hash.foo.should eql(:foo)
  end
  
  it "should map hash.bar = :foo => hash[:bar] = :foo" do
    hash[:bar].should eql(nil)
    hash.bar = :foo
    hash.bar.should eql(:foo)
    hash[:bar].should eql(:foo)
  end
  
  it "should map hash.foo? => !!hash[:foo]" do
    hash.foo?.should eql(true)
    hash.bar = 1
    hash.bar?.should eql(true)
    hash.bar = 0
    hash.bar?.should eql(0)
  end
  
  it "should map hash.undefined_prop? => false" do
    hash.undefined_prop?.should eql(false) # not defined...
  end
  
  it "should map hash.bar? = :foo to hash[:bar] = !!:foo" do
    hash.bar? = :foo
    hash[:bar].should eql(true)
    hash.bar? = 0
    hash[:bar].should eql(false)
  end
  
end
  
    