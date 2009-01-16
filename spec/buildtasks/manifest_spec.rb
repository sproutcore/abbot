require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe "namespace :manifest" do
  
  include SC::SpecHelpers
  
  before do
    @project = fixture_project :real_world
    @target = @project.target_for :sproutcore
    @buildfile = @target.buildfile
    @manifest = @target.manifest_for(:language => :fr)
    
    @target.prepare! # make sure its ready for the manifest...
  end

  def run_task(task_name)
    @buildfile.invoke task_name,
      :manifest => @manifest,
      :target =>   @target, 
      :project =>  @project, 
      :config =>   @target.config
  end

  def entry_for(filename)
    @manifest.entry_for filename, :hidden => true
  end
  
  # Verifies that the named task runs when the passed block is executed
  def should_run(task_name, &block)
    task = @buildfile.lookup(task_name)
    first_count = task.invoke_count
    yield if block_given?
    task.invoke_count.should > first_count
  end
  
  # Prepares some standard properties needed by the manifest
  describe "manifest:prepare" do
    
    def run_task; super('manifest:prepare'); end
    
    it "sets build_root => target.build_root/language/build_number" do
      run_task
      expected = File.join(@target.build_root, 'fr', @target.build_number)
      @manifest.build_root.should == expected
    end
    
    it "sets staging_root => staging_root/language/build_number" do
      run_task
      expected = File.join(@target.staging_root, 'fr', @target.build_number)
      @manifest.staging_root.should == expected
    end
  
    it "sets url_root => url_root/language/build_number" do
      run_task
      expected = [@target.url_root, 'fr', @target.build_number] * '/'
      @manifest.url_root.should == expected
    end
  
    it "sets source_root => target.source_root" do
      run_task
      @manifest.source_root.should == @target.source_root
    end
    
    it "sets index_root => index_root/language/build_number" do
      run_task
      expected = [@target.index_root, 'fr', @target.build_number] * '/'
      @manifest.index_root.should == expected
    end
    
  end
  
  # Adds a copyfile entry for each item in the source
  describe 'manifest:catalog' do
    
    def run_task
      @manifest.prepare! # this should be run first...
      super('manifest:catalog')
    end
    
    it "create an entry for each item in the target regardless of language with the relative path as filename" do
      run_task
      
      # collect filenames from target dir...
      filenames = Dir.glob(File.join(@target.source_root, '**','*'))
      filenames.reject! { |f| File.directory?(f) }
      filenames.map! { |f| f.sub(@target.source_root + '/', '') }
      filenames.reject! { |f| f =~ /^(apps|frameworks)/ }
            
      entries = @manifest.entries.dup # get entries to test...
      filenames.each do |filename|
        entry = entries.find { |e| e.filename == filename }
        if entry.nil?
          nil.should == filename # oops!  not found...
        else
          entry.filename.should == filename
          entry.build_task.should == 'build:copy'
          entry.build_path.should == File.join(@manifest.build_root, filename)
          entry.staging_path.should == File.join(@manifest.source_root, filename)
          entry.source_path.should == entry.staging_path
          entry.url.should == [@manifest.url_root, filename] * '/'
          entry.should_not be_hidden
          entry.original?.should be_true # mark as original entry
        end
          
        (entry.nil? ? nil : entry.filename).should == filename
        entries.delete entry
      end
      entries.size.should == 0
    end
    
  end
  
  describe "manifest:hide_buildfiles" do
    
    def run_task
      @manifest.prepare!
      super('manifest:hide_buildfiles')
    end
    
    it "should run manifest:catalog first" do
      should_run('manifest:catalog') { run_task }
    end
    
    it "should hide any Buildfile, sc-config, or sc-config.rb" do
      run_task
      entry_for('Buildfile').hidden?.should be_true
    end
    
    it "should hide any non .js file outside of .lproj, test, fixture, & debug dirs" do
      run_task
      entry_for('README').hidden?.should be_true
      entry_for('lib/index.html').hidden?.should be_true
      
      entry_for('tests/sample.rhtml').hidden?.should be_false
      entry_for('english.lproj/demo.html').hidden?.should be_false
      entry_for('fixtures/sample-json-fixture.json').hidden?.should be_false
      entry_for('debug/debug-resource.html').hidden?.should be_false
    end
    
    it "should NOT hide non-js files inslide lproj dirs" do
      run_task
      entry = entry_for('english.lproj/demo.html')
      entry.should_not be_hidden
    end
  
    # CONFIG.load_fixtures
    it "should hide files in /fixtures and /*.lproj/fixtures if CONFIG.load_fixtures is false" do
      @target.config.load_fixtures = false
      run_task
      entry = entry_for('fixtures/sample_fixtures.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/fixtures/sample_fixtures-loc.js')
      entry.should be_hidden
    end
    
    it "should NOT hide files in /fixtures and /*.lproj/fixtures if CONFIG.load_fixtures is true" do
      @target.config.load_fixtures = true
      run_task
      entry = entry_for('fixtures/sample_fixtures.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/fixtures/sample_fixtures-loc.js')
      entry.should_not be_hidden
    end
    
    # CONFIG.load_debug
    it "should hide files in /debug and /*.lproj/debug if CONFIG.load_debug is false" do
      @target.config.load_debug = false
      run_task
      entry = entry_for('debug/sample_debug.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/debug/sample_debug-loc.js')
      entry.should be_hidden
    end
    
    it "should NOT hide files in /debug and /*.lproj/debug if CONFIG.load_fixtures is true" do
      @target.config.load_debug = true
      run_task
      entry = entry_for('debug/sample_debug.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/debug/sample_debug-loc.js')
      entry.should_not be_hidden
    end
  
    # CONFIG.load_tests
    it "should hide files in /tests and /*.lproj/tests if CONFIG.load_tests is false" do
      @target.config.load_tests = false
      run_task
      entry = entry_for('tests/sample.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/tests/sample-loc.js')
      entry.should be_hidden
    end
    
    it "should NOT hide files in /tests and /*.lproj/tests if CONFIG.load_tests is true" do
      @target.config.load_tests = true
      run_task
      entry = entry_for('tests/sample.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/tests/sample-loc.js')
      entry.should_not be_hidden
    end
    
  end
  
  describe "manifest:localize" do
    
    def run_task
      @manifest.prepare!
      super('manifest:localize')
    end
    
    it "should run manifest:catalog && hide_buildfiles as prereq" do
      should_run('manifest:catalog') { run_task }
      should_run('manifest:hide_buildfiles') { run_task }
    end
    
    it "should not alter non-localized files" do
      run_task
      entry = entry_for('core.js')
      entry.should_not be_nil
      entry.should_not be_hidden
    end
  
    it "should mark all entries with localized? = true" do
      run_task
      @manifest.entries.each do |entry|
        if entry.source_path =~ /\.lproj/
          entry.localized?.should be_true
        else
          entry.localized?.should_not be_true
        end
      end
    end
    
    it "should remove foo.lproj from filename, build_path, and url of localized" do
      run_task
      @manifest.entries.each do |entry|
        next unless entry.localized?
        new_filename = entry.source_path.match(/\.lproj\/(.+)$/).to_a[1]
        entry.filename.should eql(new_filename)
        entry.build_path = File.join(@manifest.build_root, new_filename.split('/'))
        entry.url = [@manifest.url_root, new_filename.split('/')].flatten.join('/')
      end
    end
    
    it "should assign language to localized entries" do
      run_task
      # we just test this by spot checking to make sure any entry in the
      # french.lproj actually has a french language code assigned...
      @manifest.entries.each do |entry|
        next unless entry.localize? && (entry.source_path =~ /french\.lproj/)
        entry.language.should eql(:fr) 
      end
    end
        
    it "should not hide resources in current language" do
      run_task
      entry = entry_for('french-resource.js')
      entry.localized?.should be_true
      entry.should_not be_hidden
      entry.language.should eql(:fr)
    end
    
    it "should not hide resource in preferred language that are not also found in current language" do
      run_task
      entry = entry_for('demo.html')
      entry.localized?.should be_true
      entry.language.should eql(:en)
      entry.should_not be_hidden
    end
    
    it "should prefer resource in current language over those in preferred language" do
      run_task
      # a 'strings.js' is defined in english.lproj, french.lproj, & german
      # this should use the french version since that one is current
      entry = @manifest.entry_for('strings.js')
      entry.localized?.should be_true
      entry.should_not be_hidden
      entry.language.should eql(:fr)
    end
      
    it "should hide resources in languages not part of current language or preferred language" do
      run_task
      entry = entry_for('german-resource.js')
      entry.should be_hidden
    end
    
  end
  
  describe "manifest:prepare_build_tasks:tests" do
    
    def run_task(load_tests=true)
      @manifest.prepare!
      @target.config.load_tests = load_tests # force...
      super('manifest:prepare_build_tasks:tests')
    end
  
    it "should run manifest:localize & manifest:catalog as prereq" do
      should_run('manifest:catalog') { run_task }
      should_run('manifest:localize') { run_task }
    end
    
    it "should create a transform entry (with entry_type == :test) for every test entry" do
      run_task
      entries = @manifest.entries(:hidden => true)
    
      # find all entries referencing original source...
      source_entries = entries.reject do |entry|
        !(entry.original? && entry.filename =~ /^tests\//)
      end
      source_entries.size.should > 0 # precondition
      
      # final all test transform entries.
      test_entries = entries.reject { |e| e.entry_type != :test }
      test_entries.size.should eql(source_entries.size) # 1 for each entry?
      test_entries.each do |entry|
        source_entries.should include(entry.source_entry)
        source_entries.delete(entry.source_entry) # avoid double counting
      end
      
      # none should be left...
      source_entries.size.should == 0
    end
  
    # check the format of each entry...
    describe "transform entry" do
  
      before do
        run_task
        @entries = @manifest.entries.reject { |e| e.entry_type != :test }
      end
      
      it "changes the filename + build_path + url ext to .html" do
        @entries.each do |entry|
          File.extname(entry.filename).should == '.html'
          File.extname(entry.build_path).should == '.html'
          File.extname(entry.url).should == '.html'
        end
      end
      
      it "assigns a build_task of build:test:EXTNAME (from source_entry)" do
        @entries.each do |entry|
          extname = File.extname(entry.source_entry.filename)[1..-1]
          entry.build_task.to_s.should == "build:test:#{extname.downcase}"
        end
      end
      
    end
    
    it "should create a composite entry to generate a -index.json with test entries as source" do
      run_task
      entry = @manifest.entry_for('tests/-index.json')
      
      entry.should_not be_nil
      entry.entry_type.should == :resource
      entry.build_task.to_s.should == 'build:test:index.json'
  
      expected = @manifest.entries.reject { |e| e.entry_type != :test }
      entry.source_entries.size.should eql(expected.size)
      entry.source_entries.each do |entry|
        expected.should include(entry)
        expected.delete(entry) # avoid double counting
      end
      expected.size.should == 0 # should have an empty size...
    end
    
    it "should not hide -index.json source_entries (since they are test that need to be built)" do
      run_task
      entry = @manifest.entry_for('tests/-index.json')
      entry.source_entries.each do |entry|
        entry.should_not be_hidden
      end
    end
    
    it "should not generate an -index.json entry if tests not loaded" do
      run_task(false)
      entry = @manifest.entry_for('tests/-index.json')
      entry.should be_nil
    end
    
  end
  
  describe "manifest:prepare_build_tasks:sass" do
    
    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:sass')
    end
  
    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
    
    it "should create a transform entry (with entry_type == :css) for every sass entry" do
      run_task
      entries = @manifest.entries(:hidden => true)
    
      # find all entries referencing original source...
      source_entries = entries.reject do |entry|
        !(entry.original? && entry.filename =~ /\.sass$/)
      end
      source_entries.size.should > 0 # precondition
      
      # final all test transform entries.
      test_entries = entries.reject { |e| e.entry_type != :css }
      test_entries.size.should eql(source_entries.size) # 1 for each entry?
      test_entries.each do |entry|
        source_entries.should include(entry.source_entry)
        source_entries.delete(entry.source_entry) # avoid double counting
      end
      
      # none should be left...
      source_entries.size.should == 0
    end
  
    # check the format of each entry...
    describe "sass -> css transform entry" do
  
      before do
        run_task
        @entries = @manifest.entries.reject do |e| 
          !(e.entry_type == :css && e.source_entry.filename =~ /\.sass$/)
        end
      end
      
      it "changes the filename + build_path + url ext to .css" do
        @entries.each do |entry|
          File.extname(entry.filename).should == '.css'
          File.extname(entry.build_path).should == '.css'
          File.extname(entry.url).should == '.css'
        end
      end
      
      it "assigns a build_task of build:sass" do
        @entries.each do |entry|
          entry.build_task.to_s.should == 'build:sass'
        end
      end
      
      it "hides the source entry" do
        @entries.each do |entry|
          entry.source_entry.should be_hidden
        end
      end
      
    end # describe sass -> css transform entry
    
  end # describe manifest:prepare_build_tasks:sass
  
  describe "manifest:prepare_build_tasks:css" do

    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:css')
    end

    it "should run manifest:prepare_build_tasks:setup  && sass as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
      should_run('manifest:prepare_build_tasks:sass') { run_task }
    end
    
    describe "supports require() and sc_require() statements" do
      
      it "adds a entry.requires property to entrys with empty array of no requires are specified in file"  do
        run_task
        entry = entry_for('no_require.css')
        entry.requires.should == []
      end
      
      it "searches files for require() & sc_requires() statements and adds them to entry.requires array -- (also should ignore any ext)" do
        run_task
        entry = entry_for('has_require.css')
        entry.requires.sort.should == ['demo2', 'no_require']
      end
    
    end
    
    describe "supports sc_resource() statement" do
      it "sets entry.resource = 'stylesheet' if no sc_resource statement is found in files" do
        run_task
        entry = entry_for('no_require.css')
        entry.resource.should == 'stylesheet'
      end
      
      it "searches files for sc_resource() statement and stores last value in entry.resource property" do
        run_task
        entry  =entry_for 'sc_resource.css'
        entry.resource.should == 'bar'
      end
    end
    
    describe "combines stylesheet entries" do
      
      before do
        run_task
      end
      
      it "creates a combined stylesheet entry for each resource named in files" do
        # spot check...
        entry = entry_for 'stylesheet.css'
        entry.source_entries.should include(entry_for('has_require.css'))
        entry.source_entries.should include(entry_for('no_require.css'))

        entry = entry_for 'bar.css'
        entry.source_entries.should include(entry_for('sc_resource.css'))
      end
      
      it "entries have a build_task = build:css" do
        entry_for('stylesheet.css').build_task.should == 'build:css'
        entry_for('bar.css').build_task.should == 'build:css'
      end
      
      it "hides source entries" do
        %w(stylesheet.css bar.css).each do |filename|
          entry_for(filename).source_entries.each do |entry|
            entry.should be_hidden
          end
        end
      end
      
    end
    
  end # describe manifest:prepare_build_tasks:css

  describe "manifest:prepare_build_tasks:javascript" do

    def run_task
      @manifest.prepare!
      super('manifest:prepare_build_tasks:javascript')
    end

    it "should run manifest:prepare_build_tasks:setup as prereq" do
      should_run('manifest:prepare_build_tasks:setup') { run_task }
    end
    
    describe "supports require() and sc_require() statements" do
      
      it "adds a entry.requires property to entrys with empty array of no requires are specified in file"  do
        run_task
        entry = entry_for('no_require.js')
        entry.requires.should == []
      end
      
      it "searches files for require() & sc_requires() statements and adds them to entry.requires array -- (also should ignore any ext)" do
        run_task
        entry = entry_for('has_require.js')
        entry.requires.sort.should == ['demo2', 'no_require']
      end
    
    end
    
    describe "supports sc_resource() statement" do
      it "sets entry.resource = 'stylesheet' if no sc_resource statement is found in files" do
        run_task
        entry = entry_for('no_require.js')
        entry.resource.should == 'javascript'
      end
      
      it "searches files for sc_resource() statement and stores last value in entry.resource property" do
        run_task
        entry  =entry_for 'sc_resource.js'
        entry.resource.should == 'bar'
      end
    end
    
    describe "combines javascript entries" do
      
      before do
        run_task
      end
      
      it "creates a combined javascript entry for each resource named in files" do
        # spot check...
        entry = entry_for 'javascript.js'
        entry.source_entries.should include(entry_for('has_require.js'))
        entry.source_entries.should include(entry_for('no_require.js'))

        entry = entry_for 'bar.js'
        entry.source_entries.should include(entry_for('sc_resource.js'))
      end
      
      it "entries have a build_task = build:javascript" do
        entry_for('javascript.js').build_task.should == 'build:javascript'
        entry_for('bar.js').build_task.should == 'build:javascript'
      end
      
      it "hides source entries" do
        %w(javascript.js bar.js).each do |filename|
          entry_for(filename).source_entries.each do |entry|
            entry.should be_hidden
          end
        end
      end
      
    end
    
  end # describe manifest:prepare_build_tasks:css

end
