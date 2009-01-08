require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe 'manifest/core.rake', 'manifest:compute_build_path' do
  
  include Abbot::SpecHelpers

  it "should set MANIFEST.build_path => BUNDLE.build_root/language/build_number" do
    manifest = Abbot::HashStruct.new :language => :lang
    bundle = Abbot::HashStruct.new :build_root => "build_root", :build_number => "build_number"
    config = Abbot::HashStruct.new
    
    basic_library.buildfile.execute_task 'manifest:compute_build_path',
     :manifest => manifest, :bundle => bundle, :config => config
     
     manifest.build_path.should eql(File.join(*%w(build_root lang build_number)))
  end
end

describe 'manifest/core.rake', 'manifest:compute_url_path' do
  
  include Abbot::SpecHelpers

  it "should set MANIFEST.url_path => BUNDLE.url_root/language/build_number" do
    manifest = Abbot::HashStruct.new :language => :lang
    bundle = Abbot::HashStruct.new :url_root => "url_root", :build_number => "build_number"
    config = Abbot::HashStruct.new
    
    basic_library.buildfile.execute_task 'manifest:compute_url_path',
      :manifest => manifest, :bundle => bundle, :config => config
     
    manifest.url_path.should eql('url_root/lang/build_number')
  end
end

describe 'manifest/core.rake', 'manifest:compute_staging_path' do
  
  include Abbot::SpecHelpers

  it "should use CONFIG.staging_root/bundle_name/lang/build_number if defined" do
    manifest = Abbot::HashStruct.new :language => :lang
    bundle = Abbot::HashStruct.new :bundle_name => "bundle_name", :build_number => "build_number"
    config = Abbot::HashStruct.new :staging_root => 'staging_path'
    
    basic_library.buildfile.execute_task 'manifest:compute_staging_path',
      :manifest => manifest, :bundle => bundle, :config => config
     
    manifest.staging_path.should eql('staging_path/bundle_name/lang/build_number')
  end

  it "should generate staging path if no config defined" do
    manifest = Abbot::HashStruct.new :language => :lang
    bundle = Abbot::HashStruct.new :bundle_name => "bundle_name", :build_number => "build_number"
    config = Abbot::HashStruct.new
    
    basic_library.buildfile.execute_task 'manifest:compute_staging_path',
      :manifest => manifest, :bundle => bundle, :config => config

    ends_right = !!(manifest.staging_path =~ /\/bundle_name\/lang\/build_number$/)
    ends_right.should be_true
  end
  
end

