require File.join(File.dirname(__FILE__), %w(.. spec_helper))

describe "manifest:prepare_build_tasks:bundle_loaded" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  describe "app target" do
    
    before do
      std_before :builder_tests, :bundle_test
      
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
    
    it "should not create a bundle_loaded.js entry for an app" do
      run_task
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
    
    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end
    
    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
    
    it "should create a bundle_loaded.js entry" do
      run_task
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
    
    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end
    
    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
    
    it "should create a bundle_loaded.js entry" do
      run_task
      @manifest.entry_for('bundle_loaded.js').should_not be_nil
    end
    
  end
  
end

describe "manifest:prepare_build_tasks:bundle_info" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before :builder_tests, :bundle_test
    
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
  
  it "should create a bundle_info.js for a dynamic_required target" do
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
      std_before :builder_tests, :bundle_test
      
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
    
    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end
    
    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
    
    it "should create a bundle_info.js entry for its dynamic target" do
      @manifest.entry_for('bundle_info.js').should_not be_nil
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
      (req = @target.dynamic_required_targets).size.should == 0
    end
    
    it "should not create a bundle_info.js entry" do
      @manifest.entry_for('bundle_info.js').should be_nil
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
    
    it "should not require a dynamic framework" do
      (req = @target.dynamic_required_targets).size.should == 0
    end
    
    it "should not create a bundle_info.js entry" do
      @manifest.entry_for('bundle_info.js').should be_nil
    end
    
  end
  
end
