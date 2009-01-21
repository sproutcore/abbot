require File.join(File.dirname(__FILE__), %w(.. spec_helper))

describe "manifest:prepare_build_tasks:sass" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

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
    
    it "adds 'source' to filename + build_path + url" do
      @entries.each do |entry|
        entry.filename.should =~ /^source\//
        entry.build_path.should =~ /source/
        entry.url.should =~ /source/
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

    #### NOTE:  Currently build directives such as sc_require() and 
    #### sc_resource() are not supported in sass files.  These rules test that
    #### some basics are filled in anyway.  Feel free to add support for said
    #### directive processing if you need it and change these tests! :-)
    it "sets the entry.resource => stylesheet" do
      @entries.each do |entry|
        entry.resource.should == 'stylesheet'
      end
    end
    
    it "sets the entry.required => []" do
      @entries.each do |entry|
        entry.required.should == []
      end
    end
    
  end # describe sass -> css transform entry
end
