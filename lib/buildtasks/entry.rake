# ===========================================================================
# SC::ManifestEntry Buildtasks
# copyright 2011, Strobe Inc. and Apple Inc. all rights reserved
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
  task_options :log => :none # no logging -- too much detail
  task :prepare do |task, hash|
    entry, manifest = hash[:entry], hash[:manifest]

    filename = entry[:filename]
    raise "All entries must have a filename!" unless filename

    # If this is a composite entry, then the source_paths array should
    # contain the staging_path from the source_entries.   The source_path
    # is simply the first source_paths.
    if entry.composite?
      if source_entries = entry[:source_entries]
        entry[:source_entry] ||= source_entries.first
      else
        source_entries = entry[:source_entries] = Array(entry[:source_entry])
      end

      unless source_paths = entry[:source_paths]
        source_paths = entry[:source_paths] = source_entries.map { |e| e[:staging_path] }
      end

      entry[:source_path] ||= source_paths.first

    # Otherwise, the source_path is where we will pull from and source_paths
    # is simply the source_path in an array.
    else
      entry[:source_path] ||= File.join(manifest[:source_root], filename)
      entry[:source_paths] ||= [entry[:source_path]]
    end

    # Construct some easier paths if needed
    entry[:build_path] ||= File.join(manifest[:build_root], filename)
    entry[:url] ||= [manifest[:url_root], filename].join('/')

    # Fill in a default build task
    entry[:build_task] ||= 'build:copy'

    entry[:ext] = File.extname(filename)[1..-1]

    # If the build_task is build:copy, make the staging path equal the
    # source_root.  This is an optimization that will avoid unnecessary
    # copying.  All other build_tasks we build a staging path from the root.
    if entry[:build_task] == 'build:copy'
      entry[:staging_path] ||= entry[:source_path]
    else
      entry[:staging_path] ||= manifest.unique_staging_path(File.join(manifest[:staging_root], filename))
    end

    entry[:cache_path] = manifest.unique_cache_path(File.join(manifest[:cache_root], filename))
  end

end

