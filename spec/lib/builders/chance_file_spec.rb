require "lib/builders/spec_helper"

describe SC::Builder::ChanceFile do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :chance_test
  end

  after do
    std_after
  end


  it "should extract files from Chance instance" do

    # We create our own Chance instance and add custom files in this test.
    instance = Chance::Instance.new()

    filename = "stylesheet@test.css"
    entry = @manifest.add_entry filename,
      :chance_instance => instance,

      # Chance has a test file made just for testing purposes
      :chance_file => "chance-test.css"

    dest = entry.build_path

    # Build using the entry we created
    SC::Builder::ChanceFile.build(entry, dest)
    result = File.readlines(dest)*""

    # There is a static_url; it should be replaced, but the file does not
    # exist so itw ill turn into ''
    result.strip.should == ".hello { background: url(''); }"
  end

end

