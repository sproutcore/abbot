require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::ManifestEntry, 'hyperdomain_prefix' do
  
  include SC::SpecHelpers
  
  before do
    @project = fixture_project(:real_world)
    @target = @project.target_for :contacts
    @manifest = @target.manifest_for(:language => :en)
    
    # create entry manually to avoid calling prepare
    @entry = SC::ManifestEntry.new @manifest, 
      :filename => "filename", 
      :url => "foo",
      :source_path => "imaginary" / "path"
  end

  it "should not alter url by calling hyperdomain_prefix if hyper_domaining array is empty in config" do
    @target.config.timestamp_urls = false # preconditon for the simplicity of this test
    
    @entry.cacheable_url.should == 'foo'
  end
  
  it "should prepend a hyper domain to the url by calling hyperdomain_prefix if hyper_domaining array is NOT empty in config" do
    @target.config.timestamp_urls = false  # preconditon for the simplicity of this test
    
    @target.config.hyper_domaining = ["hyper1.sproutcore.com", "hyper2.sproutcore.com"]
    
    # hashing algorithm should pick 'hyper1.sproutcore.com' as the hyper domain
    @entry.cacheable_url.should == 'hyper1.sproutcore.com/foo'
  end

end
