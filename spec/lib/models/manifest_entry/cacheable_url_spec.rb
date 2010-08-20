require "spec_helper"

describe SC::ManifestEntry, 'timestamp_url' do

  include SC::SpecHelpers

  before do
    @project = fixture_project(:real_world)
    @target = @project.target_for :contacts
    @manifest = @target.manifest_for(:language => :en)

    # create entry manually to avoid calling prepare
    @entry = SC::ManifestEntry.new @manifest,
      :filename => "filename",
      :url => "foo",
      :source_path => "imaginary" / "path"
  end

  it "should return url itself if timestamp_url config is false" do
    @target.config.timestamp_urls = false # preconditon
    @entry.cacheable_url.should == 'foo'
  end

  it "should return url with timestamp token appended as query string if timestamp_url is true" do
    @target.config.timestamp_urls = true # preconditon
    @entry.timestamp.should_not be_blank # preconditon
    @entry.cacheable_url.should == "foo?#{@entry.timestamp}"
  end


end
