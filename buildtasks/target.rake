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
      ['/', CONFIG.url_prefix, TARGET.target_name].join('')
    
    # use index_root config or merge index_prefix + target_name
    TARGET.index_root = CONFIG.index_root || 
      ['/', CONFIG.index_prefix, TARGET.target_name].join('')

    TARGET.build_root = CONFIG.build_root || 
      File.join(PROJECT.project_root.to_s, 
        CONFIG.public_prefix.to_s, CONFIG.url_prefix.to_s, 
        TARGET.target_name.to_s)
        
    TARGET.staging_root = File.join(PROJECT.project_root.to_s, 
      (PROJECT.config.staging_prefix || 'tmp').to_s, 'staging', 
      TARGET.target_name.to_s)
    
  end

  # Invoked by sc-manifest to calculate the build number for a manifest.
  # The default implementation of this task will respect the config you set
  # or it will calculate the build number dynamically.
  # 
  task :build_number do

    # Use config build number specifically for this target, if specified
    build_number = CONFIG.build_number

    # Otherwise, look for a global build_numbers hash and try that
    if build_number.nil? && (build_numbers = CONFIG.build_numbers)
      build_number = build_numbers[TARGET.target_name.to_s] || build_numbers[TARGET.target_name.to_sym]
    end

    # Otherwise, actually compute a build number.  This may be expensive
    build_number = TARGET.compute_build_number

    # Invoke the sc-manifest tool
    TARGET.build_number = build_number
  end
  
end
