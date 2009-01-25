require File.join(File.dirname(__FILE__), %w(.. spec_helper))

describe "manifest:prepare_build_tasks:tests" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

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
        entry.build_task.to_s.should == "build:test"
      end
    end
    
  end
  
  it "should create a composite entry to generate a -index.json with test entries as source" do
    run_task
    entry = @manifest.entry_for('tests/-index.json')
    
    entry.should_not be_nil
    entry.entry_type.should == :resource
    entry.build_task.to_s.should == 'build:test_index'

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
