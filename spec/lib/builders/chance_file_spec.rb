require "lib/builders/spec_helper"

describe SC::Builder::Chance do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :chance_test
  end

  after do
    std_after
  end

  it "should extract files from Chance instance sc_require statements" do

    # We create our own Chance instance and add custom files in this test.
    instance = Chance::Instance.new()
    instance.files["test-file.css"] = ".hello { background: static_url('test.png'); }"

    # First, our fake Chance entry. We are going to set it up to copy "core.js"
    # to "core_copied.js" so we know it ran.
    chance_entry = @manifest.add_entry "core_copied.js",
      :chance => instance,
      :staging_path => File.join(@target.cache_root, 'core_copied.js'),
      :build_path => File.join(@target.build_root, 'core_copied.js'),
      :source_path => File.join(@target.source_root, 'core.js'),
      :build_task => "build:copy"

    # PRECONDITION: this file should not be copied yet!
    File.exist?(chance_entry[:staging_path]).should be_false
    File.exist?(chance_entry[:build_path]).should be_false

    # We will hand the entries over in the WRONG order, because Chance parses
    # the sc_require to determine the correct order. ordered entries should be ignored
    filename = "stylesheet@test.css"
    entry = @manifest.add_entry filename,
      :chance_entry => chance_entry,
      :chance_file => "test-file.css"

    dest = entry.build_path

    # Build using the entry we created
    SC::Builder::ChanceFile.build(entry, dest)
    result = File.readlines(dest)*""


    # Chance should have "built"
    # It should not stage. Since it will end up building anyway, if it stages it
    # will have built twice. Given that Chance is not exactly fast, this would
    # be a bug.
    File.exist?(chance_entry[:staging_path]).should be_false
    File.exist?(chance_entry[:build_path]).should be_true


    # There is a static_url; it should be replaced, but the file does not
    # exist so itw ill turn into ''
    result.strip.should == ".hello { background: url(''); }"
  end

end

