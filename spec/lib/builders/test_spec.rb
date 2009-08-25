require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::Test do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper
  
  before do
    std_before :test_test
    
    # run std rules to run manifest.  Then verify preconditions to make sure
    # no other changes to the build system effect the ability of these tests
    # to run properly.
    @manifest.build!
    @qunit_entry = @manifest.entry_for('tests/qunit_test.html')
    @rhtml_entry   = @manifest.entry_for('tests/rhtml_test.html')
    @summary_entry = @manifest.entry_for('tests.html')
  end

  after do
    std_after
  end
  
  it "VERIFY PRECONDITIONS" do
    # Verify qunit entry -- should have qunit_test.js entry
    @qunit_entry.should_not be_nil
    entry_names = @qunit_entry.source_entries.map { |e| e.filename }.sort
    entry_names.should == %w(tests/qunit_test.js)
    
    # Verify bar entry - should have 1 entry
    @rhtml_entry.should_not be_nil
    entry_names = @rhtml_entry.source_entries.map { |e| e.filename }.sort
    entry_names.should == %w(tests/rhtml_test.rhtml)
    
    # Verify summary entry - should have both bar & qunit & qunit2
    @summary_entry.should_not be_nil
    entry_names = @summary_entry.source_entries.map { |e| e.filename }.sort
    entry_names.should == %w(tests/qunit_test.js tests/qunit_test2.js tests/rhtml_test.rhtml)
  end

  describe "adding test_required frameworks urls" do
    
    before do 
      @builder = SC::Builder::Test.new(@qunit_entry)
    end
    
    it "add stylesheets for test" do
      # figure expected urls...
      t = @project.target_for(:qunit)
      url = t.manifest_for(:language => :en).build!.entry_for('stylesheet.css').url
      url = /#{Regexp.escape url}/
      
      @target.config.combine_stylesheets = true 
      @target.config.load_test = true 
      result = @builder.stylesheets_for_client
      result.should =~ url
      
      # also works for @import
      result = @builder.stylesheets_for_client(:include_method => :import)
      result.should =~ url
    end
    
    it "adds javascript for test" do
      # figure expected urls...
      t = @project.target_for(:qunit)
      t.config.combine_javascript = true
      url = t.manifest_for(:language => :en).build!.entry_for('javascript.js').url
      url = /#{Regexp.escape url}/
      
      @target.config.combine_javascript = true 
      @target.config.load_test = true
      result = @builder.javascripts_for_client
      result.should =~ url
    end
  end
    
    
  describe "layout_path" do
    
    before do 
      @builder = SC::Builder::Test.new(@qunit_entry)
    end
    
    it "initially resolves layout_path using test_layout config for target" do
      # see the Buildfile for the fixture project to see this config.
      @builder.layout_path.should == File.join(@project.project_root, %w(apps test_test lib test_layout.rhtml))
    end
    
    it "changes its resolved path if you alter the layout variable" do
      # use helper method...
      @builder.sc_resource(:layout => 'lib/alt_layout.rhtml')
      @builder.layout_path.should == File.join(@project.project_root, %w(apps test_test lib alt_layout.rhtml))
    end
  end
      

      
  describe "render a js entry" do
    
    it "should render html including JS inside a script tag for final content" do
      result = SC::Builder::Test.new(@qunit_entry).render
      result.should =~ /layout/ # verify rendered layout
      result.should =~ /\<script.*\>.*qunit_test.*\<\/script\>/m # verify js
    end
      
  end

  describe "render a rhtml entry" do
    
    it "should render html including final content and resource content" do
      result = SC::Builder::Test.new(@rhtml_entry).render
      result.should =~ /layout/ # verify rendered layout
      result.should =~ /final_test/
      result.should_not =~ /resources_test/ # resources div no longer included
    end
      
  end
  
  describe "render a summary entry" do
    
    it "should render composite with both sets of unit tests" do
      result = SC::Builder::Test.new(@summary_entry).render
      result.should =~ /layout/ # verify rendered layout
      result.should =~ /\<script.*\>.*qunit_test.*\<\/script\>/m # verify js1
      result.should =~ /\<script.*\>.*qunit_test2.*\<\/script\>/m # verify js2
      result.should =~ /final_test/
      result.should_not =~ /resources_test/ # resources div no longer included
    end
    
  end
  
  it "should import the standard html API" do
    modules = SC::Builder::Test.included_modules
    modules.should include(SC::Helpers::StaticHelper)
  end
  
end