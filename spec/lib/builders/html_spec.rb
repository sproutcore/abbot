require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::JavaScript do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper
  
  before do
    std_before :html_test
    
    # run std rules to run manifest.  Then verify preconditions to make sure
    # no other changes to the build system effect the ability of these tests
    # to run properly.
    @manifest.build!
    @index_entry = @manifest.entry_for('index.html')
    @bar_entry   = @manifest.entry_for('bar1.html')
  end
  
  it "VERIFY PRECONDITIONS" do
    @target.should be_loadable
    
    # target should require one other target...
    (req = @target.required_targets).size.should == 1
    req.first.target_name.should == :'/req_target_2'
    
    # the required target should itself require another target...
    (req = req.first.required_targets).size.should == 1
    req.first.target_name.should == :'/req_target_1'
    
    # Verify index entry -- should have erb_sample + rhtml_sample entries
    @index_entry.should_not be_nil
    entry_names = @index_entry.source_entries.map { |e| e.filename }.sort
    entry_names.should == %w(erb_sample.html.erb rhtml_sample.rhtml)
    
    # Verify bar entry - should have 1 entry
    @bar_entry.should_not be_nil
    entry_names = @bar_entry.source_entries.map { |e| e.filename }.sort
    entry_names.should == %w(bar1_sample.rhtml)
  end
  
  describe "building an index.html entry" do
  end
  
  describe "building non-index entries" do
  end
  
  # templates should expect to be able to access certain environmental 
  # variables and other commands when running.  This API is exposed as methods
  # on the HTML builder object itself.
  describe "API for templates" do
    
    before do
      # get the simplest builder...
      @builder = SC::Builder::Html.new(@bar_entry)
    end
    
    it "exposes entry = current entry" do
      @builder.entry.should == @bar_entry
    end
    
    it "exposes current target as both 'target' & 'bundle' (for backwards compatibility)" do
      @builder.bundle.should == @target
      @builder.target.should == @target
    end
    
    it "exposes current project as both 'project' & 'library' (for backwards compatibility)" do
      @builder.project.should == @project
      @builder.library.should == @project
    end
    
    it "exposes output filename as 'filename'" do
      @builder.filename.should == 'bar1.html'
    end
    
    it "exposes current language as 'language'" do
      @builder.language.should == :en
    end
    
    describe "TagHelpers" do
      it "exposes tag(br) => <br />" do
        @builder.tag(:br).should =~ /<br ?\/>/ # don't care if space is added
      end
      
      it "exposes content_tag(h1, 'hello_world')" do
        @builder.content_tag(:h1, 'hello world').should == '<h1>hello world</h1>'
      end
      
      it "exposes cdata_section('hello world')" do
        @builder.cdata_section('hello world').should == "<![CDATA[hello world]]>"
      end
      
      it "exposes escape_once('1 & 2')" do
        @builder.escape_once("1 > 2 &amp; 3").should == "1 &gt; 2 &amp; 3"
      end
    end
    
    describe "TextHelper" do

      it "exposes highlight(str, highlight_str, repl_Str)" do
        @builder.highlight('You searched for: rails', 'rails').should == 'You searched for: <strong class="highlight">rails</strong>'
      end
      
      it "exposes pluralize(cnt, 'foo')" do
        @builder.pluralize(1, 'person').should == '1 person'
        @builder.pluralize(2, 'person').should == '2 people'
        @builder.pluralize(3, 'person', 'users').should == '3 users'
      end
    
      begin
        gem 'RedCloth'
        require 'redcloth'
        
        it "exposes textilize('foo')" do
          @builder.textilize("h1. foo").should == "<h1>foo</h1>"
        end
      rescue LoadError
        puts "WARNING: Not testing textilize() because RedCloth is not installed"
      end

      begin
        gem 'bluecloth'
        require 'bluecloth'
        
        it "exposes markdown('foo')" do
          @builder.markdown("# foo").should == "<h1>foo</h1>"
        end
      rescue LoadError
        puts "WARNING: Not testing markdown() because BlueCloth is not installed"
      end
        
      ## TODO: Test remaining methods from TextHelper are added.
    end
    
  end
  
  
end