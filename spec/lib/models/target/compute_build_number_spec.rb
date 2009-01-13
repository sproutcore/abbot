require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])
require 'tempfile'
require 'fileutils'

describe SC::Target, 'compute_build_number' do

  include SC::SpecHelpers

  before do
    @project = temp_project(:real_world)
    puts @project.project_root
  end
  
  after do
    #@project.cleanup
  end
    
  it "uses the config.build_number if specified for the target" do
  end
  
  it "uses the config.build_numbers.target_name if specified and if config.build_number is not specified" do
  end

  it "generates a unique build number based on content if nothing is explicitly set" do
  end
  
  it "changes its generated build number if contents of source files change" do
  end

  it "changes generated build number if build number for a required target changes" do
  end
  
  it "does not change generated build number if a nested target that is not required by target changes" do
  end
  
end

