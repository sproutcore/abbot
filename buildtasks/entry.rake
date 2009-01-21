# ===========================================================================
# SC::ManifestEntry Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building ManifestEntry objects.  You can override these 
# tasks in your buildfiles.
namespace :entry do

  # Invoked whenever a new entry is added.  Gives you a chance to fill in any
  # standard properties. The default implementation ensures that the entry
  # has at least a source_path, build_path, staging_path, url and build_task
  #
  # With this task in place, you can build an entry by simply providing a 
  # filename and, optionally a source_path or source_entries.
  task :prepare do
    filename = ENTRY.filename
    raise "All entries must have a filename!" if filename.nil?
    
    filename_parts = filename.split('/')
    
    # If this is a composite entry, then the source_paths array should 
    # contain the staging_path from the source_entries.   The source_path
    # is simply the first source_paths.
    if ENTRY.composite?
      ENTRY.source_entries ||= [ENTRY.source_entry].compact
      ENTRY.source_paths ||= ENTRY.source_entries.map { |e| e.staging_path }
      ENTRY.source_path ||= ENTRY.source_paths.first
      ENTRY.source_entry ||= ENTRY.source_entries.first
      
    # Otherwise, the source_path is where we will pull from and source_paths
    # is simply the source_path in an array.
    else
      ENTRY.source_path ||= File.join(MANIFEST.source_root, filename_parts)
      ENTRY.source_paths ||= [ENTRY.source_path]
    end
    
    # Construct some easier paths if needed
    ENTRY.build_path ||= File.join(MANIFEST.build_root, filename_parts)
    ENTRY.url ||= [MANIFEST.url_root, filename_parts].join('/')
    
    # Fill in a default build task
    ENTRY.build_task ||= 'build:copy'
    
    ENTRY.ext = File.extname(filename)[1..-1]
    
    # If the build_task is build:copy, make the staging path equal the 
    # source_root.  This is an optimization that will avoid unnecessary 
    # copying.  All other build_tasks we build a staging path from the root.
    if ENTRY.build_task.to_s == 'build:copy'
      ENTRY.staging_path ||= ENTRY.source_path
    else
      ENTRY.staging_path ||= MANIFEST.unique_staging_path(File.join(MANIFEST.staging_root, filename_parts))
    end
  end
  
end

