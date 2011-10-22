require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:json" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:javascript')
  end

  it "should run manifest:prepare_build_tasks:setup as prereq" do
    should_run('manifest:prepare_build_tasks:setup') { run_task }
  end


  it "assigns a json build task to each json file" do
    run_task
    entries = @manifest.entries.select { |e| e.entry_type == :json }
    entries.each do |entry|
      e[:build_task].should == "build:json"
    end
  end

  describe "supports require() and sc_require() statements" do

    it "adds a entry.required property to entrys with empty array of no requires are specified in file"  do
      run_task
      entry = entry_for('source/no_require.js')
      entry.required.should == []
    end

    it "searches files for require() & sc_requires() statements and adds them to entry.required array -- (also should ignore any ext)" do
      run_task
      entry = entry_for('source/has_require.js')
      entry.required.sort.should == ['demo2', 'no_require']
    end

  end

  describe "supports sc_resource() statement" do
    it "sets entry.resource = 'javascript' if no sc_resource statement is found in files" do
      run_task
      entry = entry_for('source/no_require.js')
      entry.resource.should == 'javascript'
    end

    it "searches files for sc_resource() statement and stores last value in entry.resource property" do
      run_task
      entry  =entry_for 'source/sc_resource.js'
      entry.resource.should == 'bar'
    end
  end



end
