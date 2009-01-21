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

  after do
    std_after
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

  describe "layout_path" do
    
    before do 
      @index_builder = SC::Builder::Html.new(@index_entry)
    end
    
    it "initially resolves layout_path using layout config for target" do
      # see the Buildfile for the fixture project to see this config.
      @index_builder.layout_path.should == File.join(@project.project_root, %w(apps html_test lib layout_template.rhtml))
    end
    
    it "changes its resolved path if you alter the layout variable" do
      # use helper method...
      @index_builder.sc_resource('index', 
        :layout => 'req_target_2:lib/alt_layout.rhtml')
      
      @index_builder.layout_path.should == File.join(@project.project_root, %w(frameworks req_target_2 lib alt_layout.rhtml))
    end
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
    
    describe "Basic properties" do
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
    end
    
    # Static helper contains methods needed to generate a SproutCore app
    # such as static_url, sc_resource, etc.
    describe "StaticHelper" do
      
      it "exposes static_url() & sc_static() alias" do
        @builder.static_url('icons/image').should =~ /icons\/image.png/
        @builder.static_url('image.jpg').should =~ /image.jpg/

        @builder.sc_static('icons/image').should =~ /icons\/image.png/
        @builder.sc_static('image.jpg').should =~ /image.jpg/
      end
      
      it "takes a :language option for static_url to select an alternate manifest (deprecated - supported for backwards compatibility)" do
        @builder.static_url('fr.png', :language => :fr).should =~ /french-icons\/fr.png/
        
        @builder.sc_static('fr.png', :language => :fr).should =~ /french-icons\/fr.png/
      end
      
      it "accepts sc_resource(rsrc_name, opts).  :layout opt may be used to set layout.  otherwise this is scanned for during manifest building" do
        @builder.sc_resource('foo', :layout => 'bar')
        @builder.instance_variable_get('@layout').should == 'bar'
      end
      
      describe "exposes loc()" do
        
        it "maps passed string to local target strings.js, if present" do
          @builder.loc('local_string').should eql('LOCAL STRING')
        end
        
        it "maps passed string to required target strings.js, otherwise" do
          @builder.loc('req_string').should eql('REQ STRING')
        end
        
        it "accepts a language option to loc a different language (deprecated - included for backward compatibility)" do
          @builder.loc('local_string', :language => :fr).should eql('LOCAL STRING FR')
        end
        
      end
      
      describe "exposes stylesheets_for_client()" do
        
        # look for link tags in order...
        def expect_links(result, urls = [])
          urls = urls.dup # don't corrupt original array
          result.scan /\<link.+href\=\"([^\"]+)\"[^\<]+\/\>/ do |m|
            $1.should == urls.shift
          end
        end

        # look for link tags in order...
        def expect_imports(result, urls = [])
          urls = urls.dup # don't corrupt original array
          result.scan /@import\s+url\(\'(.+)\'\)/ do |m|
            $1.should == urls.shift
          end
        end
          
        it "generates a link to stylesheet.css entries for all required targets if CONFIG.combine_stylesheetss = true" do
          # figure expected urls...
          urls = %w(req_target_1 req_target_2 html_test).map do |target_name|
            t = @project.target_for(target_name)
            t.manifest_for(:language => :en).build!.entry_for('stylesheet.css').url
          end
          
          @target.config.combine_stylesheets = true 
          result = @builder.stylesheets_for_client
          expect_links(result, urls)
          
          # also works for @import
          result = @builder.stylesheets_for_client(:include_method => :import)
          expect_imports(result, urls)
        end
        
        it "generates a link to the ordered entries of each stylesheet.css for all required targets if CONFIG.combine_stylesheetss = false" do
          # figure expected urls...
          urls = %w(req_target_1 req_target_2 html_test).map do |target_name|
            t = @project.target_for(target_name)
            e = t.manifest_for(:language => :en).build!.entry_for('stylesheet.css')
            e.ordered_entries.map { |e| e.url }
          end
          urls.flatten!
          
          @target.config.combine_stylesheets = false 
          result = @builder.stylesheets_for_client
          expect_links(result, urls)

          result = @builder.stylesheets_for_client(:include_method => :import)
          expect_imports(result, urls)
        end
      
        it "adds stylehseet_libs to end of styles" do
          @target.config.stylesheet_libs = %w(foo bar)
          result = @builder.stylesheets_for_client
          result.should =~ /href=\"foo\"/
          result.should =~ /href=\"bar\"/
        end
      
      end
      
      describe "exposes javascript_for_client()" do
        
        # look for link tags in order...
        def expect_scripts(result, urls = [])
          urls = urls.dup # don't corrupt original array
          result.scan /\<script.+src\=\"([^\"]+)\"[^\<]+\>\s*\<\/script\>/ do |m|
            $1.should == urls.shift
          end
        end

        it "generates a link to javascript.js entries for all required targets if CONFIG.combine_javascript = true" do
          # figure expected urls...
          urls = %w(req_target_1 req_target_2 html_test).map do |target_name|
            t = @project.target_for(target_name)
            t.manifest_for(:language => :en).build!.entry_for('javascript.js').url
          end
          
          @target.config.combine_javascript = true 
          result = @builder.javascripts_for_client
          expect_scripts(result, urls)
        end
        
        it "generates a link to the ordered entries of each javascript.js for all required targets if CONFIG.combine_javascript = false" do
          # figure expected urls...
          urls = %w(req_target_1 req_target_2 html_test).map do |target_name|
            t = @project.target_for(target_name)
            e = t.manifest_for(:language => :en).build!.entry_for('javascript.js', :combined => true)
            e.ordered_entries.map { |e| e.url }
          end
          urls.flatten!
          
          @target.config.combine_javascript = false 
          result = @builder.javascripts_for_client
          expect_scripts(result, urls)
        end
        
        it "adds preferredLanguage definition" do
          result = @builder.javascripts_for_client
          result.should =~ /String.preferredLanguage = "en"/
        end
        
        it "adds javascript_libs to end of scripts" do
          @target.config.javascript_libs = %w(foo bar)
          result = @builder.javascripts_for_client
          result.should =~ /src=\"foo\"/
          result.should =~ /src=\"bar\"/
        end
      
      end
      
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
    
    describe "DomIdHelper" do
      
      it "generates a unique ID each time it is called" do
        seen_ids = []
        10.times do
          next_id = @builder.dom_id!
          seen_ids.should_not include(seen_ids)
          seen_ids << next_id
        end
      end
    end
    
    describe "CaptureHelper" do
      
      it "returns the results of the passed block - optionally passing through renderer (not tested)" do
        result = @builder.capture { 'result' }
        result.should == 'result'
      end
      
      it "adds the result of the passed block to the builder as an instance variable called @content_for_foo" do
        result = @builder.content_for(:foo) { "result" }
        @builder.instance_variable_get('@content_for_foo').should == 'result'
        result.should == ''
      end
    end
        
  end
  
  
end