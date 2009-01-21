require File.join(File.dirname(__FILE__), %w(.. spec_helper))

# Creates combined entries for javascript & css
describe "manifest:prepare_build_tasks:Strings" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end
  
  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:strings')
  end

  it "should run setup as prereq" do
    should_run("manifest:prepare_build_tasks:setup") { run_task }
  end

  it "should add strings entry if strings.js is found" do
    run_task
    @manifest.entry_for('lproj/strings.js').should_not be_nil # precondition
    @manifest.entry_for('lproj/strings.yaml', :hidden => true).should_not be_nil
  end

  describe "transform entry" do
    
    before do
      run_task
      @entry = @manifest.entry_for('lproj/strings.yaml', :hidden => true)
    end
    
    it "should hide entry" do
      @entry.should be_hidden
    end
    
    it "has entry_type = :strings" do
      @entry.entry_type.should == :strings
    end

    it "should not hide source entry" do
      @entry.source_entry.should_not be_hidden
    end
    
    it "has lproj/strings.js as source entry" do
      @entry.source_entry.filename.should == 'lproj/strings.js'
    end
    
    it "has ext of 'yaml'" do
      @entry.ext.should == 'yaml'
      @entry.filename.should =~ /\.yaml$/
    end
    
    it "has build task of build:strings" do
      @entry.build_task.to_s.should == 'build:strings'
    end
  
  end
end


