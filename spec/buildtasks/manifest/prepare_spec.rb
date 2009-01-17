require File.join(File.dirname(__FILE__), 'spec_helper')

describe "manifest:prepare" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

  def run_task; super('manifest:prepare'); end
  
  it "sets build_root => target.build_root/language/build_number" do
    run_task
    expected = File.join(@target.build_root, 'fr', @target.build_number)
    @manifest.build_root.should == expected
  end
  
  it "sets staging_root => staging_root/language/build_number" do
    run_task
    expected = File.join(@target.staging_root, 'fr', @target.build_number)
    @manifest.staging_root.should == expected
  end

  it "sets url_root => url_root/language/build_number" do
    run_task
    expected = [@target.url_root, 'fr', @target.build_number] * '/'
    @manifest.url_root.should == expected
  end

  it "sets source_root => target.source_root" do
    run_task
    @manifest.source_root.should == @target.source_root
  end
  
  it "sets index_root => index_root/language/build_number" do
    run_task
    expected = [@target.index_root, 'fr', @target.build_number] * '/'
    @manifest.index_root.should == expected
  end
  
end
