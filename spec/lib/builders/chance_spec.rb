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

  it "should combine CSS files according to sc_require statements" do
    # Chance's output is not guaranteed to be the same each time it runs.
    # It will have the same effect, but details (such as some class names)
    # will differ.
    #
    # To accurately test, we must simply look for file names in the comments
    # SCSS writes and make sure the files are in the right order.

    # First, generate the entries to be handed to the Chance entry.
    file_names = %w(z_first_file.css demo.css last_file.css)
    entries = file_names.reverse.map do |filename|
      path = File.join(@target.source_root, 'resources', filename)
      entry = @manifest.add_entry filename,
        :source_path => path,
        :staging_path => path,
        :build_path => path

      File.exist?(entry.source_path).should be_true
      entry
    end

    entries.length.should > 0
    file_names.length.should > 0

    # We will hand the entries over in the WRONG order, because Chance parses
    # the sc_require to determine the correct order. ordered entries should be ignored
    filename = "stylesheet.css"
    entry = @manifest.add_composite filename,
      :source_entries  => entries,
      :ordered_entries => entries

    dest = entry.build_path

    # Build using the entry we created
    SC::Builder::Chance.build(entry, dest)
    result = File.readlines(dest)*""

    # Check that a chance instance is created
    # since we don't have any sc_require, it should have the same output
    entry[:chance].files["chance.css"].should == result

    # We also expect the 2x to be the same.
    entry[:chance].files["chance@2x.css"].should == result

    # Check that all files were generated
    %w(chance.css chance@2x.css chance.js chance-mhtml.txt).each {|e| 
      entry[:chance].files.should include(e) 
    }

    # We loop through. If the file name matches the last one, we skip the check; if it does not,
    # we check that it is the next item in file_names
    last = "chance_main.css"
    result.gsub(/\/\* line [0-9]+, (.*?)\s*\*\//) {|e|
      next if $1 == last

      # Chance appends .scss, so we have to expect that
      last = file_names.shift + ".scss"
      $1.end_with?(last).should be_true
    }

    file_names.length.should == 0

  end


end
