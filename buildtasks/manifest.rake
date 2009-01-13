# ===========================================================================
# SC::Manifest Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Manifest objects.  You can override these 
# tasks in your buildfiles.
namespace :manifest do
  
  # Invoked just before a manifest object is built to setup any standard 
  # properties on the manifest.  The default configures a build_root, 
  # source_root, staging_root, url_root, index_root and more.
  task :prepare do
    require 'tempfile'

    # make sure a language was set
    MANIFEST.language ||= :en
    
    # build_root is target.build_root + language + build_number
    MANIFEST.build_root = File.join(TARGET.build_root, 
      MANIFEST.language.to_s, TARGET.build_number.to_s)
      
    # staging_root is target.staging_root + language + build_number
    MANIFEST.staging_root = File.join(TARGET.staging_root, 
      MANIFEST.language.to_s, TARGET.build_number.to_s)
      
    # url_root
    MANIFEST.url_root = 
      [TARGET.url_root, MANIFEST.language, TARGET.build_number].join('/')
      
    # index_root
    MANIFEST.index_root = 
      [TARGET.index_root, MANIFEST.language, TARGET.build_number].join('/')
      
  end
  
  # Invoked to actually build a manifest.  This will invoke several other 
  # tasks on the same manifest.  In a Buildfile you may choose to extend or
  # override this task to provide your own manifest generation.
  task :build do
    puts "BUILDING MANIFEST!"
    execute_task 'manifest:catalog_entries'
  end
  
  task :catalog_entries do
    source_root = MANIFEST.source_root
    Dir.glob(File.join(source_root, '**', '*')).each do |path|
      next if !File.exist?(path) || File.directory?(path)
      next if TARGET.target_directory?(path)
      filename = path.sub /^#{source_root}\//, ''
      MANIFEST.add_entry filename # entry:prepare will fill in the rest
    end
  end
  
    
end
