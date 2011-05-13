require "buildtasks/manifest/spec_helper"

# Creates combined entries for javascript & css
describe "manifest:prepare_build_tasks:combine" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    # capture any log warnings...
    @msg = capture('stderr') {
      @manifest.prepare!
      super('manifest:prepare_build_tasks:combine')
    }
  end

  it "should run setup, javascript, css, sass, & less as prereq" do
    %w(setup javascript css sass less).each do |task_name|
      should_run("manifest:prepare_build_tasks:#{task_name}") { run_task }
    end
  end

  #######################################
  # stylesheet.css support
  #
  describe "when CONFIG.combine_stylesheets = true" do

    before do
      @config.combine_stylesheets = true
      run_task
    end

    it "creates a combined stylesheet entry for each resource named in files" do
      # spot check...
      entry = entry_for 'stylesheet.css'
      expected = entry_for('source/has_require.css', :entry_type => :css)
      entry.source_entries.should include(expected)

      expected = entry_for('source/no_require.css', :entry_type => :css)
      entry.source_entries.should include(expected)

      # Test that sass file is included...
      expected = entry_for('source/demo2.css', :entry_type => :css)
      entry.source_entries.should include(expected)

      # Test that scss file is included...
      expected = entry_for('source/demo3.css', :entry_type => :css)
      entry.source_entries.should include(expected)

      # Test that less file is included...
      expected = entry_for('source/demo4.css', :entry_type => :css)
      entry.source_entries.should include(expected)

      entry = entry_for 'bar.css'
      expected = entry_for('source/sc_resource.css', :entry_type => :css)
      entry.source_entries.should include(expected)
    end

    it "entries have a build_task = build:chance_file" do
      entry_for('stylesheet.css').build_task.should == 'build:chance_file'
      entry_for('bar.css').build_task.should == 'build:chance_file'
    end

    it "hides source entries" do
      %w(stylesheet.css bar.css).each do |filename|
        entry_for(filename).source_entries.each do |entry|
          entry.should be_hidden if entry[:entry_type] == :css
        end
      end
    end


    describe "adds ENTRY.ordered_entries propery with entries following load order" do

      before do
        @project = fixture_project :ordered_entries
      end

      it "orders entries as lproj/strings -> core -> utils -> others alphabetically without requires" do

        @target = @project.target_for :no_requires
        @buildfile = @target.buildfile
        @config = @target.config
        @manifest = @target.manifest_for(:language => :en)
        @target.prepare! # make sure its ready for the manifest...

        run_task
        entry = @manifest.entry_for('stylesheet.css')

        # get the expected set of ordered entries...based on contents of
        # project...
        expected = %w(source/a.css source/a/a.css source/a/b.css source/B.css source/b/a.css source/c.css)

        entry.ordered_entries.should_not be_nil
        filenames = entry.ordered_entries.map { |e| e.filename }
        filenames.should eql(expected)
      end

      it "will override default order respecting ENTRY.required" do

        @target = @project.target_for :with_requires
        @buildfile = @target.buildfile
        @config = @target.config
        @manifest = @target.manifest_for(:language => :en)
        @target.prepare! # make sure its ready for the manifest...

        run_task
        entry = @manifest.entry_for('stylesheet.css')

        # get the expected set of ordered entries...based on contents of
        # project...
        expected = %w(source/c.css source/a.css source/b.css)

        entry.ordered_entries.should_not be_nil
        filenames = entry.ordered_entries.map { |e| e.filename }
        filenames.should eql(expected)
      end

    end

  end

  describe "when CONFIG.combine_stylesheets = false" do

    before do
      @config.combine_stylesheets = false
      run_task
    end

    it "still creates combined CSS entry" do
      entry = entry_for('stylesheet.css')
      entry.should_not be_nil
    end

    it "does not hide source CSS entries" do
      entry = entry_for('stylesheet.css')
      entry.should_not be_nil
      entry.source_entries.each { |entry| entry.should_not be_hidden }
    end
  end

  #######################################
  # javascript.js support
  #

  describe "whem CONFIG.combine_javascript = true" do

    before do
      @config.combine_javascript = true
      run_task
    end

    it "creates a combined JS entry for each resource named in files" do
      # spot check...
      entry = entry_for 'javascript.js'
      expected = entry_for('source/has_require.js', :entry_type => :javascript)
      entry.source_entries.should include(expected)

      expected = entry_for('source/no_require.js', :entry_type => :javascript)
      entry.source_entries.should include(expected)

      entry = entry_for 'bar.js'
      expected = entry_for('source/sc_resource.js', :entry_type => :javascript)
      entry.source_entries.should include(expected)
    end

    it "entries have a build_task = build:combine:javascript" do
      %w(javascript.js bar.js).each do |filename|
        entry_for(filename).build_task.should == 'build:combine'
      end
    end

    it "hides source entries" do
      %w(javascript.js bar.js).each do |filename|
        entry_for(filename).source_entries.each do |entry|
          entry.should be_hidden
        end
      end
    end

    describe "adds ENTRY.ordered_entries propery with entries following load order" do

      before do
        @project = fixture_project :ordered_entries
      end

      it "orders entries as lproj/strings -> core -> utils -> others alphabetically without requires -> resources/*_page.js -> main.js}" do

        @target = @project.target_for :no_requires
        @buildfile = @target.buildfile
        @config = @target.config
        @manifest = @target.manifest_for(:language => :en)
        @target.prepare! # make sure its ready for the manifest...

        run_task
        entry = @manifest.entry_for('javascript.js')

        # get the expected set of ordered entries...based on contents of
        # project...
        expected = %w(source/lproj/strings.js source/core.js source/utils.js __sc_chance.js source/1.js source/a.js source/a/a.js source/a/b.js source/B.js source/b/a.js source/c.js source/t.js source/resources/main_page.js source/main.js)

        entry.ordered_entries.should_not be_nil
        filenames = entry.ordered_entries.map { |e| e.filename }
        filenames.should eql(expected)
      end

      it "orders entries with APP_NAME.js before other entries" do
        @target = @project.target_for :template_style
        @buildfile = @target.buildfile
        @config = @target.config
        @manifest = @target.manifest_for(:language => :en)
        @target.prepare! # make sure its ready for the manifest...

        run_task
        entry = @manifest.entry_for('javascript.js')

        # get the expected set of ordered entries...based on contents of
        # project...
        expected = %w(source/template_style.js source/a.js)

        entry.ordered_entries.should_not be_nil
        filenames = entry.ordered_entries.map { |e| e.filename }
        filenames.should eql(expected)

      end

      it "will override default order respecting ENTRY.required" do

        @target = @project.target_for :with_requires
        @buildfile = @target.buildfile
        @config = @target.config
        @manifest = @target.manifest_for(:language => :en)
        @target.prepare! # make sure its ready for the manifest...

        run_task
        entry = @manifest.entry_for('javascript.js')

        # get the expected set of ordered entries...based on contents of
        # project... note that we require 'd', which should match 'lproj/d'
        expected = %w(__sc_chance.js source/c.js source/a.js source/lproj/d.js source/b.js)

        entry.ordered_entries.should_not be_nil
        filenames = entry.ordered_entries.map { |e| e.filename }
        filenames.should eql(expected)
      end

    end

  end

  describe "when CONFIG.combine_javascript = false" do

    before do
      @config.combine_javascript = false
      run_task
    end

    it "still creates combined JS entry" do
      entry = entry_for('javascript.js')
      entry.should_not be_nil
    end

    it "does not hide source JS entries" do
      entry = entry_for('javascript.js')
      entry.should_not be_nil
      entry.source_entries.each { |entry| entry.should_not be_hidden }
    end
  end

  describe "when no modules are specified for an app"  do

    before do
      run_task
    end

    it "contains all modules as requirements" do
      target = target_for('calendar')
      requirements = target.required_targets

      preferences_modules = target_for('calendar/preferences')
      requirements.should include(preferences_modules)
    end
  end

  describe "when a subset of modules are specified "  do

    before do
      run_task
    end

    it "does not require any modules in its requried_targets" do
      target = target_for('contacts')
      requirements = target.required_targets

      modules = requirements.select{ |target| target[:target_type] == :module }

      modules.should be_empty
    end

    it "contains only the specified modules" do
      target = target_for('contacts')
      modules = target.modules

      preferences_module = target_for('contacts/preferences')
      printing_module = target_for('contacts/printing')

      modules.should include(preferences_module)
      modules.should_not include(printing_module)
    end
  end

  describe "when a deferred modules requires another module "  do
    before do
      run_task
    end

    it "the deferred module should list the required module in its requirements" do
      target = target_for('mail')
      target_requirements = target.required_targets

      preferences_module = target.target_for('mail/preferences')
      printing_module = target.target_for('mail/printing')

      preferences_requirements = preferences_module.required_targets

      target_requirements.should_not include(preferences_module)
      preferences_requirements.should include(printing_module)
    end
  end

  describe "when an inline_module is defined"  do
    before do
      run_task
    end

    it " should be included in the requirements" do
      target = target_for('photos')
      target_requirements = target.required_targets

      preferences_module = target.target_for('photos/preferences')
      email_module = target.target_for('photos/email')

      target_requirements.should include(preferences_module)
      target_requirements.should_not include(email_module)
    end
  end
end
