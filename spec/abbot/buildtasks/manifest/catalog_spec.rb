require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe 'manifest/catalog.rake', 'manifest:catalog' do
  
  include Abbot::SpecHelpers

  it "should simply create entries for every source file with a build:copy task" do
    
    # Get the manifest & reset it so we can invoke just the build rule we 
    # want. -- then build with our rule only so we can test the results
    manifest = basic_library.bundle_for(:app1).manifest_for(:en).reset!
    manifest.entries.size.should eql(0)
    
    manifest.build! 'manifest:catalog'

    # find all of the files in the target project that should be in target
    src_root = manifest.bundle.source_root
    src_paths = Dir.glob(File.join(src_root,'**','*'))
    
    # no directories
    src_paths.reject! { |f| File.directory?(f) }
    
    # test paths start from source_root
    src_paths.map! { |path| path.sub /^#{src_root}\//, '' }
    
    # exclude directories that may contain other bundles
    src_paths.reject! { |path| path =~ /^(apps|clients|frameworks)/ }

    # now make sure the cataloged entries include all of the src_paths and no
    # extras
    manifest.entries.size.should eql(src_paths.size)
    manifest.entries.each do |entry|
      
      # Verify that each entry is only included once..
      src_paths.should include(entry.filename)
      src_paths.delete entry.filename
      
      # Verify entry's source_path && staging_path == source_root + filename
      expected_path = File.join(src_root, entry.filename)
      entry.source_path.should eql(expected_path)
      entry.staging_path.should eql(expected_path)
      
      # Verify entry's build_path == manifest.build_path + filename
      expected_path = File.join(manifest.build_path, entry.filename)
      entry.build_path.should eql(expected_path)
      
      # Verify entry's build_task == "build:copy"
      entry.build_task.to_s.should eql('build:copy')
      
      # Entry's ext...
      entry.ext.should eql(File.extname(entry.filename)[1..-1] || '')
      
    end

  end
end

