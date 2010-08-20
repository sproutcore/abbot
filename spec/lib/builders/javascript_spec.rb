require "lib/builders/spec_helper"

describe SC::Builder::JavaScript do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :javascript_test

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
      SC::Builder::JavaScript.build(entry, dst_path)
    end
  end

  it "converts calls to sc_super() => arguments.callee.base.apply()" do
    lines = run_builder 'sc_super.js'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /sc_super\(/
      line.should =~ /arguments.callee.base.apply\(this,arguments\)/
    end
  end

  it "converts static_url() and sc_static() => 'url('foo')' " do
    lines = run_builder 'sc_static.js'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /(static_url|sc_static)/
      line.should =~ /'.+'/ # important MUST have some url...
    end
  end

  it "static_url() and sc_static() respect timestamp_urls" do
    @target.config.timestamp_urls = false
    lines = run_builder 'sc_static.js'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /'.+\?.+'/ # important MUST NOT have some url w/ timestamp...
    end

    @target.config.timestamp_urls = true
    lines = run_builder 'sc_static.js'
    lines.each do |line|
      next if line.size == 1
      line.should =~ /'.+\?.+'/ # important MUST have some url w/ timestamp...
    end
  end

  it "removes server-side keys from localized strings.js files" do
    lines = run_builder 'strings.js', true
    @entry.should be_localized
    lines.each do |line|
      next if line.size == 1 # skip empty lines
      line.should_not =~ /@@foo/ # make sure key is removed...
    end
  end

  it "should not remove server-side keys from strings.js files that are not found in an .lproj (i.e. not localized)" do
    lines = run_builder 'strings.js', false # <-- NOT localized.
    @entry.should_not be_localized
    lines.each do |line|
      next if line.size == 1 # skip empty lines
      next if line =~ /\s*\/\// # skip comment lines
      line.should =~ /@@foo/ # make sure key is NOT removed...
    end
  end


end
