

require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:chance" do
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before(:real_world, :no_2x)
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:chance')
  end

  it "should run manifest:prepare_build_tasks:setup as prereq" do
    should_run('manifest:prepare_build_tasks:setup') { run_task }
  end


  def have_entry(name, have=true)
    entry = @manifest.entry_for name
    if have
      entry.should_not be_nil
    else
      entry.should be_nil
    end
  end

  it "does not generate @2x when not needed" do
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
      have_entry(name + "@2x.css", false)

      # check that transforms are created
      entries.each {|entry|
        entry.should be_transform
        entry.source_entry.should_not be_nil
        originals.should include(entry)
        originals.delete(entry)
      }

    end
    originals.size.should == 0
  end

end

