require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::Stylesheet do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper
  
  before do
    std_before :stylesheet_test
  end

  def run_builder(filename)
    super do |entry, dst_path|
      SC::Builder::Stylesheet.build(entry, dst_path)
    end
  end
    
  # This test passes a test fixture file through the builder that contains 
  # examples of all the different ways these directives might appear in a 
  # file to try to trip up the regex.  If you find additional examples that
  # cause problems, add them to the fixture file so that this test breaks.
  it "wraps require(), sc_require(), & sc_resource() in comments" do
    lines = run_builder 'build_directives.css'
    lines.each do |line|
      next if line.size == 1
      line.should =~ /\/\*.+(require|sc_require|sc_resource).+\*\//
    end
  end

  it "converts static_url() and sc_static() => 'url('foo')' " do
    lines = run_builder 'sc_static.css'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /(static_url|sc_static)/
      line.should =~ /url\('.+'\)/ # important MUST have some url...
    end
  end
  
end
