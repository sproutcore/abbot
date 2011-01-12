require "lib/builders/spec_helper"

describe 'SC::Builder::Module' do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  describe "app target" do

    before do
      std_before :bundle_test

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      # At present, the loadable property is set only for apps
      @target.should be_loadable
    end

    it "should require one static target" do
      (req = @target.required_targets).size.should == 1
      req.first.target_name.should == :'/req_target_1'
    end

    it "should require one dynamic target" do
      (req = @target.modules).size.should == 1
      req.first.target_name.should == :'/req_target_2'
    end
  end

  describe "static framework target" do

    before do
      std_before :req_target_1

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      @target.should_not be_loadable
    end
  end

  describe "dynamic framework target" do

    before do
      std_before :req_target_2

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      @target.should_not be_loadable
    end
  end

end

describe 'SC::Builder::BundleInfo' do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  describe "app target" do

    before do
      std_before :bundle_test

      # most of these tests assume load_debug is turned off like it would be
      # in production mode
      @target.config.load_debug = false
      @target.config.theme = nil
      @target.config.use_packed = false
      @target.config.timestamp_urls = false

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      @target.should be_loadable
    end

    it "should require one static target" do
      (req = @target.required_targets).size.should == 1
      req.first.target_name.should == :'/req_target_1'
    end

    it "should require one dynamic target" do
      (req = @target.modules).size.should == 1
      req.first.target_name.should == :'/req_target_2'
    end
  end

  describe "static framework target" do

    before do
      std_before :req_target_1

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      @target.should_not be_loadable
    end

    it "should not require a dynamic framework" do
      (req = @target.modules).size.should == 0
    end
  end

  describe "dynamic framework target" do

    before do
      std_before :req_target_2

      # most of these tests assume load_debug is turned off like it would be
      # in production mode
      @target.config.load_debug = false
      @target.config.theme = nil
      @target.config.timestamp_urls = false

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

    after do
      std_after
    end

    it "VERIFY PRECONDITIONS" do
      @target.should_not be_loadable
    end

    it "should require its own dynamic framework" do
      (req = @target.modules).size.should == 1
    end
  end

end
