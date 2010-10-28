require "lib/builders/spec_helper"
require 'yaml'

describe SC::Builder::Strings do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :strings_test

    # add fake strings entry
    @source_entry = @manifest.add_entry 'lproj/strings.js',
      :build_task => 'build:copy'

    @entry = @manifest.add_transform @source_entry,
      :ext => 'yaml',
      :entry_type => :yaml,
      :build_task => 'build:strings'

  end


  after do
    std_after
  end

  # Note, the string.js fixture file this test loads should stress the
  # builder to make sure it can parse various cases.
  it "generates a yaml file with contents of string.js parsed into a hash" do
    pending "what is this YAML file used for?"

    dst_path = @entry.staging_path
    SC::Builder::Strings.build(@entry, dst_path)
    File.exist?(dst_path).should be_true

    # get YAML
    require 'yaml'
    yaml = YAML.load(File.read(dst_path))
    yaml.should_not be_nil

    expected = {
      'test1' => "test1",
      'test2' => 'test2 "with quotes"',
      'test3' => "test3",
      "test4" => 'test4'
    }
    yaml.keys.size.should == expected.keys.size
    expected.each do |key, value|
      yaml[key].should == value
    end
  end

end


