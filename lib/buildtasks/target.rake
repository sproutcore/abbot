# ===========================================================================
# SC::Target Buildtasks
# copyright 2011, Strobe Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.
namespace :target do

  # Invoked whenever a new target is created to prepare standard properties
  # needed on the build system.  Extend this task to add other standard
  # properties
  task :prepare do |task, env|

    target = env[:target]
    config = CONFIG
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

    url_prefix = (config[:url_prefix] || '').gsub(/^[^\/]+:\/\/[^\/]+\//,'')

    # Set up root paths
    %w(build staging cache).each do |type|
      root_key = "#{type}_root".to_sym
      root = config[root_key]
      prefix = config["#{type}_prefix".to_sym]

      path = root
      unless path
        base = prefix || ''
        # Check if it's absolute, if not add project_root
        unless base[0..0] == '~' || File.absolute_path(base) == base
          base = File.join((project.project_root || '').to_s, base)
        end
        path = File.join(base, url_prefix, (target[:target_name] || '').to_s)
      end

      target[root_key] = File.expand_path(path)
    end

    target[:build_number] = target.compute_build_number

    # The target is loadable if it is an app
    target[:loadable] = target[:target_type] == :app
  end

end
