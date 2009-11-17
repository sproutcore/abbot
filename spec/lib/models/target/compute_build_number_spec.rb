require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])
require 'tempfile'
require 'fileutils'

describe SC::Target, 'compute_build_number' do

  include SC::SpecHelpers

  before do
    @project = temp_project(:real_world)
  end
  
  after do
    @project.cleanup
  end
    
  def add_dummyfile(project)
    file = File.new(File.join(project.source_root, 'dummyfile'), 'w')
    file.write "TEST!"
    file.close
  end
    
  it "uses the config.build_number if specified for the target" do
    # add build number for target to general buildfile
    @project.buildfile.define! do
      config :sproutcore, :build_number => 'foo'
    end
    target = @project.target_for(:sproutcore)
    target.compute_build_number.should eql('foo')
  end
  
  it "uses the config.build_numbers.target_name if specified" do
    # add a build_numbers hash
    @project.buildfile.define! do
      config :all, :build_numbers => { '/sproutcore' => 'foo' }
    end
    target = @project.target_for(:sproutcore)
    target.compute_build_number.should eql('foo')
  end
  
  it "uses config.build_numbers.target_name, even if specified with symbols" do
    @project.buildfile.define! do
      config :all, :build_numbers => { :'/sproutcore' => :foo }
    end
    target = @project.target_for(:sproutcore)
    target.compute_build_number.should eql('foo')
  end
    
  
  describe "accurate method to compute build number" do
    
    before do
      @target = @project.target_for(:sproutcore).prepare!
      @target.config.build_numbers = nil #precondition
      @target.config.build_number = nil  #precondition
    end
      
    it "generates a unique build number based on content if nothing is explicitly set" do
      @target.compute_build_number.should_not be_nil
    end
  
    it "changes its generated build number if contents of source files change" do
      old_build_number = @target.compute_build_number
    
      # write an extra file into target for testing
      add_dummyfile(@target)
    
      # get new build number
      new_build_number = @target.compute_build_number
      new_build_number.should_not eql(old_build_number)
    end
  end

  it "changes generated build number if build number for a required target changes" do
    target = @project.target_for(:sproutcore).prepare!
    target.should_not be_nil

    required = target.target_for(:desktop).prepare!
    required.should_not be_nil
    required.config.build_numbers = nil #precondition
    required.config.build_number = nil  #precondition
  
    target.config.build_numbers = nil #precondition
    target.config.build_number = nil  #precondition
    target.required_targets.should include(required) #precondition
  
    old_build_number = target.compute_build_number
  
    # write an extra file into required target for testing -- changes number
    add_dummyfile(required)
  
    # get new build number
    new_build_number = target.compute_build_number
    new_build_number.should_not eql(old_build_number)
  end

  it "does not change generated build number if a nested target that is not required by target changes" do
    target = @project.target_for(:sproutcore).prepare!
    target.should_not be_nil

    not_required = target.target_for(:mobile).prepare!
    not_required.should_not be_nil

    #precondition
    target.expand_required_targets.should_not include(not_required) 
  
    target = @project.target_for(:sproutcore)
    old_build_number = target.compute_build_number
  
    # write an extra file into required target for testing -- changes number
    add_dummyfile(not_required)
  
    # get new build number
    new_build_number = target.compute_build_number
    new_build_number.should eql(old_build_number)
  end
  
  it "recursively required project should not cause an error" do
    recursive = fixture_project(:recursive_project)
    target = recursive.target_for :sproutcore
    lambda { target.compute_build_number }.should_not raise_error
  end
  
end

