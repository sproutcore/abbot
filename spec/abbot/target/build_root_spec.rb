require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Target, 'target_for' do

  include Abbot::SpecHelpers

  before do
    @project = real_world_project
    @target = @project.target_for(:sproutcore)
  end

  it "should use build_root config if defined" do
    @target.buildfile.define! do 
      config :all, :build_root => "ROOT"
    end
    @target.reload_config!
    @target.build_root.should eql("ROOT")
  end
  
  it "should compute build_root using project_root + build_prefix + url_prefix + target_name if config not set" do
    expected = [@project.project_root, 'public', 'static', 'sproutcore']
    @target.build_root.should eql(File.join(*expected))
  end
  
  it "should override computed values if value is actually set at runtime" do
    @target.build_root = "OVERRIDE"
    @target.build_root.should eql("OVERRIDE")
  end

end
