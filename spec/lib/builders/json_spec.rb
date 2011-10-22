require "lib/builders/spec_helper"

describe SC::Builder::JSON do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :json_test

    # add fake image entry for sc_static tests..
    @manifest.add_entry 'icons/image.png'
    @target.config.timestamp_urls = false
  end


  after do
    std_after
  end

  def run_builder(filename, localize=false)
    super(filename) do |entry, dst_path|
      entry[:localized] = true if localize
      SC::Builder::JSON.build(entry, dst_path)
    end
  end

  it "converts static_url() and sc_static() => 'url('foo')' " do
    lines = run_builder 'sc_static.json'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /(static_url|sc_static)/
      line.should =~ /'.+'/ # important MUST have some url...
    end
  end

  it "static_url() and sc_static() respect timestamp_urls" do
    @target.config.timestamp_urls = false
    lines = run_builder 'sc_static.json'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /'.+\?.+'/ # important MUST NOT have some url w/ timestamp...
    end

    @target.config.timestamp_urls = true
    lines = run_builder 'sc_static.json'
    lines.each do |line|
      next if line.size == 1
      line.should =~ /'.+\?.+'/ # important MUST have some url w/ timestamp...
    end
  end

end
