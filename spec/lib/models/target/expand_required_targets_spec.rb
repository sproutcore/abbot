require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Target, 'expand_required_targets' do

  include SC::SpecHelpers

  it "should return all of targets required by a target in proper order" do
    @project = fixture_project(:real_world)
    target = @project.target_for :sproutcore
    required = target.expand_required_targets.map { |x| x.target_name }
    required.should eql([
      :"/sproutcore/costello", 
      :"/sproutcore/foundation", 
      :"/sproutcore/application", 
      :"/sproutcore/data_store", 
      :"/sproutcore/desktop"])
  end
  
  it "should still return a valid response even with a recursive project" do
    @project = fixture_project(:recursive_project)
    target = @project.target_for :sproutcore
    
    required = nil 
    lambda { required = target.expand_required_targets }.should_not raise_error
    
    required.map! { |x| x.target_name }
    required.should eql([:'/sproutcore/costello'])
  end
  
end