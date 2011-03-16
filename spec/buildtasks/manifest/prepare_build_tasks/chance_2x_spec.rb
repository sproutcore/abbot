require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:chance" do
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:chance')
  end

  it "should run manifest:prepare_build_tasks:setup as prereq" do
    should_run('manifest:prepare_build_tasks:setup') { run_task }
  end


  def have_entry(name)
    entry = @manifest.entry_for name
    entry.should_not be_nil
  end

  it "generates @2x for each resource" do
    run_task

    resources = {}

    originals = @manifest.entries(:hidden=>true).select {|entry|
      entry.entry_type == :css and not entry.combined and not entry[:resource].nil?
    }
    originals.size.should > 0

    originals.each do |entry|
      next if entry[:resource].nil?

      resources[entry[:resource]] ||= []
      resources[entry[:resource]] << entry
    end

    resources.each do |name, entries|
      have_entry(name + ".css")
      have_entry(name + "@2x.css")

      # check that transforms are created
      entries.each {|entry|
        entry.should be_transform
        entry.source_entry.should_not be_nil
        originals.should include(entry)
        originals.delete(entry)
      }

      x2_entry = entry_for(name + "@2x.css")
      x2_entry[:chance_file].should == "chance@2x.css"
    end
    originals.size.should == 0
  end

  it "generates js, and mhtml entries" do
    run_task

    have_entry('stylesheet.css')
    have_entry('stylesheet@2x.css')
    have_entry('__sc_chance.js')
    have_entry('__sc_chance_mhtml.txt')

    stylesheet = entry_for('stylesheet.css')
  end

  it "provides all chance instances to the mhtml and js entries" do
    run_task

    js_entry = entry_for('__sc_chance.js')
    mhtml_entry = entry_for('__sc_chance_mhtml.txt')

    resources = {}

    originals = @manifest.entries(:hidden=>true).select {|entry|
      entry.entry_type == :css and not entry.combined and not entry[:resource].nil?
    }
    originals.size.should > 0

    originals.each do |entry|
      next if entry[:resource].nil?

      resources[entry[:resource]] ||= []
      resources[entry[:resource]] << entry
    end

    resources.each do |name, entries|
      chance_instance = entry_for(name + ".css")[:chance_instance]
      js_entry.chance_instances.should include(chance_instance)
      mhtml_entry.chance_instances.should include(chance_instance)
    end

  end
end

