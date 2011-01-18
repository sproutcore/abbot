require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:module_info" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before :builder_tests, :module_test

    # most of these tests assume load_debug is turned off like it would be
    # in production mode
    @target.config.load_debug = false
    @target.config.theme = nil
    @target.config.timestamp_urls = false

    # run std rules to run manifest.  Then verify preconditions to make sure
    # no other changes to the build system effect the ability of these tests
    # to run properly.
    @manifest.build!
  end

  it "should create a module_info.js for a deferred_modules target" do
    # run_task
    # entries = @manifest.entries.select { |e| e.entry_type == :javascript }
    # entries.each do |entry|
    #   %w(filename url build_path).each do |key|
    #     entry[key].should =~ /source\//
    #   end
    # end
  end

  describe "app target" do

    before do
      std_before :builder_tests, :module_test

      # most of these tests assume load_debug is turned off like it would be
      # in production mode
      @target.config.load_debug = false
      @target.config.theme = nil
      @target.config.use_packed = false
      @target.config.timestamp_urls = false

      @target.modules.length should (be > 0)

      # make sure all targets have the same settings...
      @target.expand_required_targets.each do |t|
        t.config.timestamp_urls = false
      end

      # make sure all targets have the same settings...
      @target.modules.each do |t|
        t.config.timestamp_urls = false
      end

      # run std rules to run manifest.  Then verify preconditions to make sure
      # no other changes to the build system effect the ability of these tests
      # to run properly.
      @manifest.build!
    end

    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end

    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
  end

  describe "static framework target" do

    before do
      std_before :builder_tests, :req_target_1

      # most of these tests assume load_debug is turned off like it would be
      # in production mode
      @target.config.load_debug = false
      @target.config.theme = nil
      @target.config.timestamp_urls = false

      # run std rules to run manifest.  Then verify preconditions to make sure
      # no other changes to the build system effect the ability of these tests
      # to run properly.
      @manifest.build!
    end

    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end

    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end

    it "should not require a dynamic framework" do
      (req = @target.modules).size.should == 0
    end
  end

  describe "dynamic framework target" do

    before do
      std_before :builder_tests, :req_target_2

      # most of these tests assume load_debug is turned off like it would be
      # in production mode
      @target.config.load_debug = false
      @target.config.theme = nil
      @target.config.timestamp_urls = false

      # run std rules to run manifest.  Then verify preconditions to make sure
      # no other changes to the build system effect the ability of these tests
      # to run properly.
      @manifest.build!
    end

    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end

    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end

    it "should require its own dynamic framework" do
      (req = @target.modules).size.should == 1
    end
  end

end
