require "lib/builders/spec_helper"

describe SC::Builder::Combine do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :combine_test
  end

  after do
    std_after
  end
  
  def verify_combine(main_entryname, filename_ext, src_root=nil)
    # generate artificial entries to test.
    source_entries = %w(a b c).map do |filename|
      filename = filename.ext(filename_ext)
      source_path = File.join(*([@target.source_root, src_root, filename.ext(filename_ext)].compact))
      @entry = @manifest.add_entry filename,
        :source_path  => source_path,
        :staging_path => source_path,
        :build_path   => source_path
      
      File.exist?(@entry.source_path).should be_true # precondition
      @entry
    end
    
    # generate wrapper to entry...
    filename = main_entryname.ext(filename_ext)
    @entry = @manifest.add_composite filename,
      :source_entries  => source_entries,
      :ordered_entries => source_entries
    
    @dst_path = @entry.build_path

    # Generate expected...
    expected = <<EOF
/* >>>>>>>>>> BEGIN a.#{filename_ext} */
CONTENT: a

/* >>>>>>>>>> BEGIN b.#{filename_ext} */
CONTENT: b !important - no newline at end
/* >>>>>>>>>> BEGIN c.#{filename_ext} */
CONTENT: c

EOF

    # OK, now do the build...
    SC::Builder::Combine.build(@entry, @dst_path)

    # And read in the result
    result = File.readlines(@dst_path)*""
    result.should eql(expected)
  end
    
      
  it "should combine JavaScript files according to ordered_entries, with separators in between" do
    verify_combine 'javascript', 'js'
  end
  
  it "should combine CSS files according to ordered_entries with separators in between" do
    verify_combine 'stylesheet', 'css', 'english.lproj'
  end
  
end
