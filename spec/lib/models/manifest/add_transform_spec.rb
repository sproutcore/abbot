require "spec_helper"

describe SC::Manifest, 'add_transform' do

  include SC::SpecHelpers

  before do
    @project = empty_project  # no buildfile to avoid running extra code...
    @project.add_target '/default', :default, :source_root => @project.project_root
    @target = @project.target_for :default
    @manifest = @target.manifest_for :language => :en

    @entry = @manifest.add_entry 'foobar.js',
      :build_task => 'build:copy',
      :source_path => File.join('source', 'foobar.js'),
      :build_path => File.join('build', 'foobar.js'),
      :staging_path => File.join('staging', 'foobar.js'),
      :cache_path => File.join('cache', 'foobar.js'),
      :url => File.join('url', 'foobar.js')
  end

  it "should add a composite entry with entry as source" do
    new_entry = @manifest.add_transform @entry, :build_task => 'foo'
    new_entry.composite?.should be_true
    new_entry.source_entries.should == [@entry]
  end

  it "copy the filename and build_path if no overrides are passed" do
    new_entry = @manifest.add_transform @entry
    new_entry.filename.should == @entry.filename
    new_entry.build_path.should == @entry.build_path
  end

  it "uses the filename and build_path in options if passed" do
    new_entry = @manifest.add_transform @entry, :filename => "foo", :build_path => "bar"
    new_entry.filename.should == "foo"
    new_entry.build_path.should == "bar"
  end

  it "should unique the staging path each time it is called" do
    # try once...
    entry1 = @manifest.add_transform @entry
    entry1.staging_path.should_not == @entry.staging_path

    # try again...
    entry2 = @manifest.add_transform @entry
    entry2.staging_path.should_not == @entry.staging_path
    entry2.staging_path.should_not == entry1.staging_path

    # try chaining...
    entry3 = @manifest.add_transform entry1
    entry3.staging_path.should_not == @entry.staging_path
    entry3.staging_path.should_not == entry1.staging_path
    entry3.staging_path.should_not == entry2.staging_path
  end

  it "should hide the original entry" do
    new_entry = @manifest.add_transform @entry, :build_task => 'foo'
    @entry.should be_hidden
  end

  it "should mark the new entry as a transform" do
    new_entry = @manifest.add_transform @entry, :build_task => 'foo'
    new_entry.should be_transform
  end

  it "swaps extensions in filename, url, build_path, and staging_path if :ext option is provided" do
    # Check preconditions
    File.extname(@entry.filename).should == '.js'
    File.extname(@entry.build_path).should == '.js'
    File.extname(@entry.url).should == '.js'
    File.extname(@entry.staging_path).should == '.js'

    # Create new entry
    new_entry = @manifest.add_transform @entry, :ext => "html"

    File.extname(new_entry.filename).should == '.html'
    File.extname(new_entry.build_path).should == '.html'
    File.extname(new_entry.url).should == '.html'
    File.extname(new_entry.staging_path).should == '.html'
  end

  it "rebases the staging path for transform entry to staging_root if original staging_path == source_path" do

    @entry.staging_path = @entry.source_path
    @manifest.staging_root = "staging/"
    new_entry = @manifest.add_transform @entry
    new_entry.staging_path.should =~ /^staging\//
  end

end
