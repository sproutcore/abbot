# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.
namespace :target do

  # Invoked whenever a new target is created to prepare standard properties 
  # needed on the build system.  Extend this task to add other standard
  # properties
  task :prepare do

    # use url_root config or merge url_prefix + target_name
    TARGET.url_root = CONFIG.url_root || 
      [nil, CONFIG.url_prefix, TARGET.target_name].join('/').gsub(/\/+/,'/')
    
    # use index_root config or merge index_prefix + target_name
    TARGET.index_root = CONFIG.index_root || 
      [nil, CONFIG.index_prefix, TARGET.target_name].join('/').gsub(/\/+/, '/')

    # Split all of these paths in case we are on windows...
    TARGET.build_root = File.expand_path(CONFIG.build_root || 
      File.join(PROJECT.project_root.to_s, 
        (CONFIG.build_prefix || '').to_s.split('/'), 
        (CONFIG.url_prefix || '').to_s.split('/'), 
        TARGET.target_name.to_s.split('/')))
        
    TARGET.staging_root = File.expand_path(CONFIG.staging_root ||
      File.join(PROJECT.project_root.to_s, 
        (CONFIG.staging_prefix || '').to_s.split('/'), 
        (CONFIG.url_prefix || '').to_s.split('/'), 
        TARGET.target_name.to_s))
      
    TARGET.build_number = TARGET.compute_build_number
    
  end
  
end
