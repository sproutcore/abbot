require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::Test do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper
  
  before do
    std_before :test_test
    
    # run std rules to run manifest.  Then verify preconditions to make sure
    # no other changes to the build system effect the ability of these tests
    # to run properly.
    @manifest.build!
    @qunit_entry = @manifest.entry_for('tests/qunit_test.html')
    @rhtml_entry   = @manifest.entry_for('tests/rhtml_test.html')
    @index_entry = @manifest.entry_for('tests/-index.json')
  end

  after do
    std_after
  end
  
  it "VERIFY PRECONDITIONS" do
    # Verify qunit entry -- should have qunit_test.js entry
    @index_entry.should_not be_nil
  end
  
  it "should generate json with entries for both qunit & rhtml entry" do
    dst_path = @index_entry.build_path
    SC::Builder::TestIndex.build(@index_entry, dst_path)
    
    require 'json'
    File.exist?(dst_path).should be_true
    result = JSON.parse(File.read(dst_path))
    result.size.should == 2
    result.each do |item|
      entry = (item['filename'] =~ /qunit_test/) ? @qunit_entry : @rhtml_entry
      item['filename'].should == entry.filename.ext('')
      item['url'].should == entry.url
    end
  end
  
end