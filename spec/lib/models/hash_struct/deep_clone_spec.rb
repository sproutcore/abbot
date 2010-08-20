require "spec_helper"

describe SC::HashStruct, 'deep_clone' do

  it "should deep_clone any objects that respond to deep_clone" do
    a = SC::HashStruct.new
    a[:b] = SC::HashStruct.new :c => :d
    
    e = a.deep_clone
    e[:b][:c] = :f
    
    e[:b][:c].should eql(:f)    
    a[:b][:c].should eql(:d)
  end
  
  it "should clone any objects that respond to clone" do
    a = SC::HashStruct.new
    a[:b] = [1,2,3]
    
    b = a.deep_clone
    b[:b][0] = 4
    
    a[:b][0].should eql(1)
    b[:b][0].should eql(4)
  end
  
end
