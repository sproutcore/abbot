# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.
namespace :target do

  # Invoked whenever a new target is created to prepare standard properties
  # needed on the build system.  Extend this task to add other standard
  # properties
  task :prepare do |task, env|

    target = env[:target]
    config = env[:config]
    project = env[:project]

    # use url_root config or merge url_prefix + target_name
    if (target[:url_root] = config[:url_root]).nil?
      url = [nil, config[:url_prefix], target[:target_name]].join('/')
      url = url.gsub(/([^:])\/+/,'\1/').gsub(/^\/+/,'/') # remove extra //
      url = url[1..-1] if url.match(/^\/[^\/]+:\/\//) # look for protocol
      target[:url_root] = url
    end


    # use index_root config or merge index_prefix + target_name
    if (target[:index_root] = config[:index_root]).nil?
      url = [nil, config[:index_prefix], target[:target_name]].join('/')
      url = url.gsub(/([^:])\/+/,'\1/').gsub(/^\/+/,'/') # remove extra //
      url = url[1..-1] if url.match(/^\/[^\/]+:\/\//) # look for protocol
      target[:index_root] = url
    end

    url_prefix = config[:url_prefix]
    url_prefix = url_prefix.gsub(/^[^\/]+:\/\/[^\/]+\//,'') if url_prefix

    # Split all of these paths in case we are on windows...
    target[:build_root] = File.expand_path(config[:build_root] ||
      File.join(project.project_root.to_s,
        (config[:build_prefix] || '').to_s.split('/'),
        (url_prefix || '').to_s.split('/'),
        target[:target_name].to_s.split('/')))

    target[:staging_root] = File.expand_path(config[:staging_root] ||
      File.join(project.project_root.to_s,
        (config[:staging_prefix] || '').to_s.split('/'),
        (url_prefix || '').to_s.split('/'),
        target[:target_name].to_s))

    # cache is used to store intermediate files
    target[:cache_root] = File.expand_path(config[:cache_root] ||
      File.join(project.project_root.to_s,
        (config[:cache_prefix] || '').to_s.split('/'),
        (url_prefix || '').to_s.split('/'),
        target[:target_name].to_s))

    target.build_number = target.compute_build_number

    # The target is loadable if it is an app
    target[:loadable] = target[:target_type] == :app
  end

end
