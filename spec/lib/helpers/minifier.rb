require 'spec_helper'

describe SC::Helpers::Minifier do
  include SC::SpecHelpers

  before do
    @project  = temp_project :helper_tests
    @target   = @project.target_for :minifier_test
    @manifest = @target.manifest_for :language => :en
    @manifest.prepare!
  end

  it "saves items to be minified" do
    SC::Helpers::Minifier << "/test/path"
    SC::Helpers::Minifier << "/second/path"
    
    SC::Helpers::Minifier.queue.should include("/test/path")
    SC::Helpers::Minifier.queue.should include("/second/path")
  end
  
  it "minifies a file when given a path" do
    source_path = File.join(@target.source_root, 'core.js')

    SC::Helpers::Minifier.minify!(source_path)

    # Fixture file contains nothing but comments. They should all be removed
    # after minification.
    IO.read(source_path).should == ""
  end

end