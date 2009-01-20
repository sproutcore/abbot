require File.join(File.dirname(__FILE__), %w(.. spec_helper))

# This task prepares a single CSS entry for every untagged source entry.
describe "manifest:prepare_build_tasks:css" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end
  
  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:css')
  end

  it "should run manifest:prepare_build_tasks:setup as prereq" do
    should_run('manifest:prepare_build_tasks:setup') { run_task }
  end

  it "creates a transform entry for each css entry" do
    run_task

    # find all original CSS entries...
    originals = @manifest.entries(:hidden => true).select do |entry|
      entry.original? && entry.ext == 'css'
    end
    originals.size.should > 0 # precondition
    
    # transformed entries
    entries = @manifest.entries.select { |e| e.entry_type == :css }
    entries.size.should == originals.size #precondition
    
    # one transformed entry should exist for each original entry.
    entries.each do |entry|
      entry.should be_transform
      entry.source_entry.should_not be_nil
      originals.should include(entry.source_entry)
      originals.delete(entry.source_entry) # so as not to allow doubles
    end
    originals.size.should == 0
  end
  
  describe "supports require() and sc_require() statements" do
    
    it "adds a entry.required property with empty array of no requires are specified in file"  do
      run_task
      entry = @manifest.entry_for('no_require.css')
      entry.required.should == []
    end
    
    it "searches files for require() & sc_requires() statements and adds them to entry.required array -- (also should ignore any ext)" do
      run_task
      entry = @manifest.entry_for('has_require.css')
      entry.required.sort.should == ['demo2', 'no_require']
    end
  
  end
  
  describe "supports sc_resource() statement" do
    it "sets entry.resource = 'stylesheet' if no sc_resource statement is found in files" do
      run_task
      entry = @manifest.entry_for('no_require.css')
      entry.resource.should == 'stylesheet'
    end
    
    it "searches files for sc_resource() statement and stores last value in entry.resource property" do
      run_task
      entry = @manifest.entry_for 'sc_resource.css'
      entry.resource.should == 'bar'
    end
  end

end
