require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Target, 'url_root' do

  include SC::SpecHelpers

  before do
    @project = real_world_project
    @target = @project.target_for(:sproutcore)
  end

  it "should use url_root config if defined" do
    @target.buildfile.define! do 
      config :all, :url_root => "ROOT"
    end
    @target.reload_config!
    @target.url_root.should eql("ROOT")
  end
  
  it "should compute url_root using url_prefix + target_name if config not set" do
    @target.url_root.should eql('/static/sproutcore')
  end
  
  it "should override computed values if value is actually set at runtime" do
    @target.url_root = "OVERRIDE"
    @target.url_root.should eql("OVERRIDE")
  end
  
end
