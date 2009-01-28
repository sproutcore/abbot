require File.join(File.dirname(__FILE__), %w(.. spec_helper))

describe "manifest:prepare_build_tasks:tests" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before #load real_world project
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
  
  it "should create a transform entry (with entry_type == :test) for every test entry with a javascript transform entry in between" do
    run_task
    entries = @manifest.entries(:hidden => true)
  
    # find all entries referencing original source...
    source_entries = entries.reject do |entry|
      !(entry.original? && entry.filename =~ /^tests\//)
    end
    source_entries.size.should > 0 # precondition
    
    # final all test transform entries - i.e. those working on single tests.
    test_entries = entries.select do |e|
      e.entry_type == :test && e.transform?
    end
    
    test_entries.size.should eql(source_entries.size) # 1 for each entry?
    test_entries.each do |entry|

      # if the source_entry is a javascript, then there should be a transform
      # in between to handle things list static_url()
      original = entry.source_entry
      if original.ext == 'js'
        original.should be_transform
        original.build_task.should == 'build:javascript'
        original = original.source_entry # get true original to test with...
      end
      
      # get original and delete from found originals to make sure chain 
      # exists...
      original.should be_original # precondition
      source_entries.should include(original)
      source_entries.delete(original) # avoid double counting
    end
    
    # none should be left...
    source_entries.size.should == 0
  end
  
  it "should create a composite entry for all tests" do
    run_task
    
    # find all entries referencing original source...
    entries = @manifest.entries(:hidden => true)
    source_entries = entries.reject do |entry|
      !(entry.original? && entry.filename =~ /^tests\//)
    end
    source_entries.sort! { |a,b| a.filename.to_s <=> b.filename.to_s }
    
    # find composite test entry
    entry = @manifest.entry_for 'tests.html', :entry_type => :test
    entry.should_not be_nil
    
    # get originals.  since some entries will be JS transforms, just walk 
    # back...
    originals = entry.source_entries.map do |entry|
      entry.transform? ? entry.source_entry : entry
    end
    found = originals.sort { |a,b| a.filename.to_s <=> b.filename.to_s }
    found.should == source_entries
  end    

  it "should create a composite entry for each nested directory" do
    run_task
    
    # find all entries referencing original source...
    entries = @manifest.entries(:hidden => true)
    source_entries = entries.reject do |entry|
      !(entry.original? && entry.filename =~ /^tests\/nested\//)
    end
    source_entries.sort! { |a,b| a.filename.to_s <=> b.filename.to_s }
    
    # find composite test entry
    entry = @manifest.entry_for 'tests/nested.html', :entry_type => :test
    entry.should_not be_nil
    originals = entry.source_entries.map do |entry|
      entry.transform? ? entry.source_entry : entry
    end
    found = originals.sort { |a,b| a.filename.to_s <=> b.filename.to_s }
    found.should == source_entries
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
    
    it "assigns a build_task of build:test" do
      @entries.each do |entry|
        extname = File.extname(entry.source_entry.filename)[1..-1]
        entry.build_task.to_s.should == "build:test"
      end
    end
    
  end
  
  it "should create a composite entry to generate a -index.json with test entries as source (excluding composite summary entries)" do
    run_task
    entry = @manifest.entry_for('tests/-index.json')
    
    entry.should_not be_nil
    entry.entry_type.should == :resource
    entry.build_task.to_s.should == 'build:test_index'

    expected = @manifest.entries.select do |e| 
      e.entry_type == :test && e.transform?
    end
    
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
