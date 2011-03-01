require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:handlebars" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:handlebars')
  end

  it "should run manifest:prepare_build_tasks:setup as a prereq" do
    should_run("manifest:prepare_build_tasks:setup") { run_task }
  end

  it "creates a transform entry for each handlebars entry" do
    run_task

    originals = @manifest.entries(:hidden => true).select do |entry|
      entry.original? && entry.ext == 'handlebars'
    end

    originals.size.should > 0

    entries = @manifest.entries.select { |e| e.entry_type == :javascript }
    entries.size.should == originals.size

    entries.each do |entry|
      entry.should be_transform
      entry.source_entry.should_not be_nil
      originals.should include(entry.source_entry)
    end
  end
end
