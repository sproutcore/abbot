require "buildtasks/manifest/spec_helper"

describe "manifest:catalog" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    @manifest.prepare! # this should be run first...
    super('manifest:catalog')
  end

  it "create an entry for each item in the target regardless of language with the relative path as filename" do
    run_task

    # collect filenames from target dir...
    filenames = Dir.glob(File.join(@target.source_root, '**','*'))
    filenames.reject! { |f| File.directory?(f) }
    filenames.map! { |f| f.sub(@target.source_root + '/', '') }
    filenames.reject! { |f| f =~ /^(apps|frameworks|themes)/ }

    entries = @manifest.entries.dup # get entries to test...
    filenames.each do |filename|
      entry = entries.find { |e| e.filename == filename }
      if entry.nil?
        nil.should == filename # oops!  not found...
      else
        entry.filename.should == filename
        entry.build_task.should == 'build:copy'
        entry.build_path.should == File.join(@manifest.build_root, filename)
        entry.staging_path.should == File.join(@manifest.source_root, filename)
        entry.source_path.should == entry.staging_path
        entry.url.should == [@manifest.url_root, filename] * '/'
        entry.should_not be_hidden
        entry.original?.should be_true # mark as original entry
      end

      (entry.nil? ? nil : entry.filename).should == filename
      entries.delete entry
    end
    entries.size.should == 0
  end

end
