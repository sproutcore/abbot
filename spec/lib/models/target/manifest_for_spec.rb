require "spec_helper"

describe SC::Target, 'manifest_for' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)
    @target = @project.target_for :sproutcore
  end
  
  it "should return a new manifest instance for a new variation with variation properties set" do
    manifest = @target.manifest_for :language => :en
    manifest.should_not be_nil
    manifest.language.should eql(:en)
  end
  
  it "should return the same manifest instance for the same variation" do
    manifest_en = @target.manifest_for :language => :en
    manifest_fr = @target.manifest_for :language => :fr
    
    @target.manifest_for(:language => :en).should eql(manifest_en)
    @target.manifest_for(:language => :fr).should eql(manifest_fr)
  end
  
  it "should return first manifest matching variation if multiples match" do
    manifest1 = @target.manifest_for :language => :en, :vers => 1
    manifest2 = @target.manifest_for :language => :en, :vers => 2

    found = @target.manifest_for(:language => :en)
    found.vers.should eql(1)
  end
  
  # IMPORTANT:  This condition is assumed by the manifest/prepare_spec.
  it "should NOT call prepare! when creating a new manifest" do
    manifest = @target.manifest_for :language => :en
    manifest.prepared?.should be_false
  end
  
end


