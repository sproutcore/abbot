require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Target, 'target_for' do

  include SC::SpecHelpers

  before do
    @project = real_world_project
    @target = @project.target_for(:sproutcore)
  end
  
  it "should lookup absolute target names (/foo) from the top" do
    target = @target.target_for('/contacts')
    target.should_not be_nil
    target.target_name.to_s.should eql('/contacts')
  end
  
  it "should look for relative names in children first" do
    # note: uploader should exist both in /apps and /sproutcore/frameworks
    target = @target.target_for(:uploader)
    target.should_not be_nil
    target.target_name.to_s.should eql('/sproutcore/uploader')
  end

  it "should look for relative names in sibling after children" do
    target = @target.target_for(:core_photos)
    target.should_not be_nil
    target.target_name.to_s.should eql('/core_photos')
  end

  it "should look for relative names in parents after siblings" do
    @target = @project.target_for('sproutcore/costello')
    target = @target.target_for(:contacts)
    target.should_not be_nil
    target.target_name.to_s.should eql('/contacts')
  end

  it "should not find nested targets without naming parents" do
    @target = @project.target_for(:contacts)
    target = @target.target_for(:costello)
    target.should be_nil
  end

  it "should be able to handle multiple/relative/names" do
    @target = @project.target_for(:contacts)
    target = @target.target_for('sproutcore/costello')
    target.should_not be_nil
    target.target_name.to_s.should eql('/sproutcore/costello')
  end
  
  it "should return nil if no matching target could be found" do
    target = @target.target_for(:does_not_exist)
    target.should be_nil
  end
  
end
