require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Project, 'target_for' do

  include SC::SpecHelpers

  before do
    @project = real_world_project
  end
  
  it "should lookup absolute target names (/foo) from the top" do
    target = @project.target_for('/sproutcore')
    target.should_not be_nil
    target.target_name.to_s.should eql('/sproutcore')
  end
  
  it "should lookup relative target names from the top (like absolute)" do
    target = @project.target_for(:sproutcore)
    target.should_not be_nil
    target.target_name.to_s.should eql('/sproutcore')
  end
  
  it "should return nil if no matching target could be found" do
    target = @project.target_for(:does_not_exist)
    target.should be_nil
  end
  
  it "should call prepare! on new targets" do
    target = @project.target_for(:contacts)
    target.prepared?.should be_true
  end
  
end
