require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::BundleLoaded do
  
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
      @target.should be_loadable
    end
    
    it "should require one static target" do
      (req = @target.required_targets).size.should == 1
      req.first.target_name.should == :'/req_target_1'
    end
    
    it "should require one dynamic target" do
      (req = @target.dynamic_required_targets).size.should == 1
      req.first.target_name.should == :'/req_target_2'
    end
    
    it "should not create a bundle_loaded.js entry for an app" do
      @manifest.entry_for('bundle_loaded.js').should be_nil
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
    
    it "should create a bundle_loaded.js entry" do
      @manifest.entry_for('bundle_loaded.js').should_not be_nil
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
    
    it "should create a bundle_loaded.js entry" do
      @manifest.entry_for('bundle_loaded.js').should_not be_nil
    end
    
  end
  
end

describe SC::Builder::BundleInfo do
  
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
      @target.dynamic_required_targets.each do |t|
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
      (req = @target.dynamic_required_targets).size.should == 1
      req.first.target_name.should == :'/req_target_2'
    end
    
    it "should create a bundle_info.js entry for its dynamic target" do
      @manifest.entry_for('bundle_info.js').should_not be_nil
    end
    
    describe "bundle_info.js" do
      
      it "should have SC::Target#bundle_info return the correct requires, css_urls and js_urls" do
        dynamic_target = @target.dynamic_required_targets[0]
        dynamic_target.should_not be_nil
        
        bundle_info = dynamic_target.bundle_info({ :variation => @manifest.variation })
        bundle_info.should_not be_nil
        
        (req = bundle_info[:requires]).size.should == 1
        req.first.target_name.should == :'/req_target_1'
        
        (req = bundle_info[:css_urls]).size.should == 1
        req.first.should == '/static/req_target_2/en/current/stylesheet.css'
        
        (req = bundle_info[:js_urls]).size.should == 4
        req[0].should == '/static/req_target_2/en/current/bundle_info.js'
        req[1].should == '/static/req_target_2/en/current/source/javascript.js'
        req[2].should == '/static/req_target_2/en/current/source/req_js_2.js'
        req[3].should == '/static/req_target_2/en/current/bundle_loaded.js'
      end
      
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
      (req = @target.dynamic_required_targets).size.should == 0
    end
    
    it "should not create a bundle_info.js entry" do
      @manifest.entry_for('bundle_info.js').should be_nil
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
      @target.dynamic_required_targets.each do |t|
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
      (req = @target.dynamic_required_targets).size.should == 1
    end
    
    it "should create a bundle_info.js entry" do
      @manifest.entry_for('bundle_info.js').should_not be_nil
    end
    
    describe "bundle_info.js" do
      
      it "should have SC::Target#bundle_info return the correct requires, css_urls and js_urls" do
        dynamic_target = @target.dynamic_required_targets[0]
        dynamic_target.should_not be_nil
        
        bundle_info = dynamic_target.bundle_info({ :variation => @manifest.variation })
        bundle_info.should_not be_nil
        
        (req = bundle_info[:requires]).size.should == 0
        
        (req = bundle_info[:css_urls]).size.should == 1
        req.first.should == '/static/dynamic_req_target_1/en/current/stylesheet.css'
        
        (req = bundle_info[:js_urls]).size.should == 2
        req[0].should == '/static/dynamic_req_target_1/en/current/source/dynamic_req_js_1.js'
        req[1].should == '/static/dynamic_req_target_1/en/current/bundle_loaded.js'
      end
      
    end
    
  end
  
end