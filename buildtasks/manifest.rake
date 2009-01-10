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
  
end
