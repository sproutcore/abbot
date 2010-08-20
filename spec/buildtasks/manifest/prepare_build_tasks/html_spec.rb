require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:html" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:html')
  end

  it "should run manifest:prepare_build_tasks:setup & strings as prereq" do
    %w(setup).each do |task_name|
      should_run("manifest:prepare_build_tasks:#{task_name}") { run_task }
    end
  end

  describe "supports sc_resource() statement" do
    it "sets entry.resource = 'index' if no sc_resource statement is found in files" do
      run_task
      entry = entry_for('no_sc_resource.rhtml')
      entry.resource.should == 'index'
    end
    
    it "searches files for sc_resource() statement and stores last value in entry.resource property" do
      run_task
      entry = entry_for 'sc_resource.rhtml'
      entry.resource.should == 'bar'
    end
  end

  describe "annotates entries with render_task" do
    
    before do
      run_task
    end
    
    it "file.erb => render:erubis" do
      expected = entry_for('file_extension_test.html.erb')
      expected.render_task.should == "render:erubis"
    end

    it "file.haml => render:haml" do
      expected = entry_for('file_extension_test.haml')
      expected.render_task.should == "render:haml"
    end

    it "file.rhtml => render:erubis" do
      expected = entry_for('file_extension_test.rhtml')
      expected.render_task.should == "render:erubis"
    end

  end
  
  describe "special case handling of index.html for loadable targets" do
    
    before do
      # load application target instead of framework...
      @target = @project.target_for :contacts
      @buildfile = @target.buildfile
      @config = @target.config
      @manifest = @target.manifest_for(:language => :fr)
      @target.prepare!

      run_task
      @index_entry = entry_for 'index.html'
    end
    
    it "applies these rules only to a target that is loadable" do
      @target.should be_loadable # precondition
    end
    
    # an index.html is always needed for an application to load properly
    # even if not explicit fragments are present in the app.
    it "generates an index.html entry even if there are no source html fragments" do
      @index_entry.should_not be_nil
      @index_entry.source_entries.size.should == 0 # precondition
    end
    
    it "does not hide the index.html entry" do
      @index_entry.should_not be_hidden
    end
    
    it "adds the include_required_targets? property to the entry" do
      @index_entry.should be_include_required_targets
    end
    
    it "marks the target as loadable" do
      @target.should be_loadable
    end
  
  end
    
  describe "special case handling of index.html for frameworks" do
    
    before do
      run_task
      @index_entry = entry_for 'index.html'
      @bar_entry = @manifest.entry_for('bar.html')
    end
    
    it "applies these rules only to a target that is not loadable" do
      @target.should_not be_loadable # precondition
    end
    
    it "hides an index.html entry" do
      @index_entry.should be_hidden
    end
    
    it "does not add include_required_targets property to entry" do
      @index_entry.should_not be_include_required_targets
    end
    
    it "should not hide other .html entries if the target is not loadable" do
      @bar_entry.should_not be_hidden
    end
    
  end
  
  describe "combines html entries into one output file per resource" do
    
    before do
      run_task
      @index_entry = entry_for 'index.html'
      @bar_entry = @manifest.entry_for('bar.html')
    end
    
    it "should be composite entries" do
      @index_entry.should be_composite
      @bar_entry.should be_composite
    end
    
    it "should include any files ending in .rhtml" do
      expected = entry_for('file_extension_test.rhtml')
      @index_entry.source_entries.should include(expected)
    end
    
    it "should include any files ending in .erb" do
      expected = entry_for('file_extension_test.html.erb')
      @index_entry.source_entries.should include(expected)
    end

    it "should include any files ending in .haml" do
      expected = entry_for('file_extension_test.haml')
      @index_entry.source_entries.should include(expected)
    end

    it "creates a combined index entry for each resource named in files" do
      # spot check...
      @index_entry.source_entries.should include(entry_for('no_sc_resource.rhtml'))

      @bar_entry.source_entries.should include(entry_for('sc_resource.rhtml'))
    end
    
    it "entries have a build_task = build:html" do
      @index_entry.build_task.should == 'build:html'
      @bar_entry.build_task.should == 'build:html'
    end
    
    it "hides source entries" do
      [@index_entry, @bar_entry].each do |entry|
        entry.source_entries.each do |source_entry|
          source_entry.should be_hidden
        end
      end
    end
    
  end

end
