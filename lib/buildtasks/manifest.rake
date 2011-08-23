# ===========================================================================
# SC::Manifest Buildtasks
# copyright 2011, Strobe Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Manifest objects.  You can override these
# tasks in your buildfiles.

require File.dirname(__FILE__) + '/helpers/acceptable_file_list_factory'

namespace :manifest do

  desc "Invoked just before a manifest object is built to setup standard properties"
  task :prepare do |task, env|
    require 'tempfile'

    manifest = env[:manifest]
    target   = env[:target]

    # make sure a language was set
    manifest[:language] ||= :en

    # build_root is target.build_root + language + build_number
    manifest[:build_root] = File.join(target[:build_root],
      manifest[:language].to_s, target[:build_number].to_s)

    # staging_root is target.staging_root + language + build_number
    manifest[:staging_root] = File.join(target[:staging_root],
      manifest[:language].to_s, target[:build_number].to_s)

    # cache_root is target.cache_root + language + build_number
    manifest[:cache_root] = File.join(target[:cache_root],
      manifest[:language].to_s, target[:build_number].to_s)

    # url_root
    manifest[:url_root] =
      [target[:url_root], manifest[:language], target[:build_number]].join('/')

    # index_root
    manifest[:index_root] =
      [target[:index_root], manifest[:language], target[:build_number]].join('/')

    # source_root
    manifest[:source_root] = target[:source_root]
  end

  desc "Actually builds a manifest.  This will catalog all entries and then filter them"
  task :build => %w(catalog hide_buildfiles localize prepare_build_tasks:all)

  desc "Builds a manifest, this adds a copy file entry for every whitelisted file in the source"
  task :catalog do |t, env|
    target   = env[:target]
    manifest = env[:manifest]

    source_root = target[:source_root]

    acceptable_file_list = AcceptableFileListFactory.build

    number_rejected_entries = 0

    Dir.glob("#{source_root}/**/*").each do |path|
      next unless File.file?(path)
      next if target.target_directory?(path)
      if acceptable_file_list.acceptable_file?(path)
        filename = path.sub /^#{Regexp.escape source_root}\//, ''
        filename = filename.split(::File::SEPARATOR).join('/')
        manifest.add_entry filename, :original => true # entry:prepare will fill in the rest
      else
        number_rejected_entries += 1
      end
    end

      if number_rejected_entries > 0
        SC.logger.warn "The Whitelist file rejected #{number_rejected_entries} file(s) from #{target[:target_name]}"
      end
  end

  desc "hides structural files that do not belong in build include Buildfiles and debug or fixtures if turned off"
  task :hide_buildfiles => [:catalog] do |task, env|
    manifest = env[:manifest]

    # these directories are to be excluded unless CONFIG.load_"dirname" = true
    dirnames = %w(debug tests fixtures protocols).reject do |k|
      CONFIG[:"load_#{k}"]
    end

    # loop through entries and hide those that do not below...
    manifest.entries.each do |entry|

      # if in /dirname or /foo.lproj/dirname -- hide it!
      dirnames.each do |dirname|
        if entry[:filename] =~ /^(([^\/]+)\.lproj\/)?#{dirname}\/.+$/
          entry.hide!
          next
        end
      end

      # allow if it is a handlebars template
      next if entry[:ext] == "handlebars"

      # otherwise, allow if inside lproj
      next if entry.localized? || entry[:filename] =~ /^.+\.lproj\/.+$/

      # allow if in tests, fixtures or debug as well...
      next if entry[:filename] =~ /^(resources|tests|fixtures|debug)\/.+$/

      # or skip if ext not js
      entry.hide! if entry[:ext] != 'js'
    end
  end

  desc "localizes files. reject any files from other languages"
  task :localize => [:catalog, :hide_buildfiles] do |task, env|
    target   = env[:target]
    manifest = env[:manifest]

    seen = {} # already seen entries...
    preferred_language = target.config[:preferred_language] || :en

    manifest.entries.each do |entry|

      # Is a localized resource!
      if entry[:filename] =~ /^([^\/]+)\.lproj\/(.+)$/
        entry[:language] = (SC::Target::LONG_LANGUAGE_MAP[$1.to_s.downcase.to_sym]) || $1.to_sym
        entry[:localized] = true

        # remove .lproj dir from build paths as well..
        lang_dir = "#{$1}.lproj/"
        sub_str = (entry[:ext] == 'js') ? 'lproj/' : ''
        entry[:filename  ] = entry[:filename].sub(lang_dir, sub_str)
        entry[:build_path] = entry[:build_path].sub(lang_dir, sub_str)
        entry[:url]        = entry[:url].sub(lang_dir, sub_str)

        # if this is part of the current language, always include...
        # hide any preferred_language entry...
        if entry[:language] == manifest[:language]
          if seen[entry[:filename]]
            seen[entry[:filename]].hide!
          else
            seen[entry[:filename]] = entry
          end

        # if this is a preferred_language, hide unless we've seen one
        elsif entry[:language].to_s == preferred_language.to_s
          if seen[entry[:filename]]
            entry.hide!
          else
            seen[entry[:filename]] = entry
          end

        # Otherwise, hide it...
        else
          entry.hide!
        end

      # Not a localized resource
      else
        entry[:language] = manifest[:language]
        entry[:localized] = false
      end
    end
  end

  namespace :prepare_build_tasks do

    desc "main entrypoint for preparing all build tasks.  This should invoke all needed tasks"
    task :all => %w(css handlebars javascript module_info sass less combine string_wrap minify string_wrap html strings tests packed)

    desc "executes prerequisites needed before one of the subtasks can be invoked.  All subtasks that have this as a prereq"
    task :setup => %w(manifest:catalog manifest:hide_buildfiles manifest:localize)

    desc "create builder tasks for all unit tests based on file extension."
    task :tests => :setup do |task, env|
      manifest = env[:manifest]

      # Generate test entries
      test_entries = []
      entries_by_dirname = {} # for building composites...
      manifest.entries.each do |entry|
        next unless entry[:filename] =~ /^tests\//

        # if this is a js file, add js transform first to handle sc_static()
        # etc.
        if entry[:ext] == 'js'
          entry = manifest.add_transform entry,
            :build_task => 'build:javascript'
        end

        # Add transform to build into test.
        test_entries << manifest.add_transform(entry,
          :build_task => "build:test",
          :entry_type => :test,
          :ext        => 'html')

        # Strip off dirnames, saving each by dirname...
        dirname = entry[:filename]
        while (dirname = dirname.sub(/\/?[^\/]+$/,'')).size > 0
          (entries_by_dirname[dirname] ||= []) << entry
        end
      end

      # Generate composite entries for each directory...
      entries_by_dirname.each do |dirname, entries|
        filename = "#{dirname}.html"
        manifest.add_composite filename,
          :build_task     => "build:test",
          :entry_type     => :test,
          :ext            => 'html',
          :source_entries => SC::Helpers::EntrySorter.sort(entries),
          :hide_entries   => false
      end

      # Add summary entry
      if CONFIG[:load_tests]
        manifest.add_entry 'tests/-index.json',
          :composite      => true,
          :source_entries => test_entries,
          :build_task     => 'build:test_index',
          :entry_type     => :resource
      end
    end
    task :javascript => :tests # IMPORTANT! to avoid JS including unit tests.
    # task :html       => :tests # IMPORTANT! to avoid HTML including tests 

    desc "scans for javascript files, annotates them and prepares combined entries for each output target"
    task :javascript => :setup do |task, env|
      manifest = env[:manifest]
      config   = CONFIG

      # select all original entries with with ext of css
      entries = manifest.entries.select do |e|
        e.original? && e[:ext] == 'js'
      end

      # add transform & tag with build directives.
      entries.each do |entry|
        entry = manifest.add_transform entry,
          :lazy_instantiation => config[:lazy_instantiation],
          :notify_onload => !config[:combine_javascript],
          :filename   => ['source', entry[:filename]].join('/'),
          :build_path => File.join(manifest[:build_root], 'source', entry[:filename]),
          :url => [manifest[:url_root], 'source', entry[:filename]].join("/"),
          :build_task => 'build:javascript',
          :resource   => 'javascript',
          :entry_type => :javascript
        entry.discover_build_directives!
      end
    end

    desc "scans for css files, creates a transform and annotates them"
    task :css => :setup do |task, env|
      manifest = env[:manifest]
      config = env[:target].config

      # select all original entries with with ext of css
      entries = manifest.entries.select do |e|
        e.original? && ['css', 'scss'].include?(e[:ext])
      end

      # add transform & tag with build directives.
      entries.each do |entry|
        filename = entry[:filename]

        # We want it to appear as CSS
        filename.gsub! /\.scss$/, '.css'

        entry = manifest.add_transform entry,
          :filename   => ['source', filename].join('/'),
          :build_path => File.join(manifest[:build_root], 'source', entry[:filename]),
          :url => [manifest[:url_root], 'source', entry[:filename]].join("/"),
          :build_task => 'build:css',
          :resource   => 'stylesheet',
          :entry_type => :css,
          :ext => 'css',
          :from_scss => (entry[:ext] == 'scss')   # for testing
        entry.discover_build_directives!
      end
    end

    desc "scans for image files, creates a transform and annotates them"
    task :images => :setup do |task, env|
      manifest = env[:manifest]
      config = env[:target].config

      # select all original entries with with ext of png, jpg, jpeg or gif
      entries = manifest.entries.select do |e|
        e.original? && ['png', 'jpg', 'jpeg', 'gif'].include?(e[:ext])
      end

      # add transform & tag with build directives.
      entries.each do |entry|
        entry = manifest.add_transform entry,
          :filename   => ['source', entry[:filename]].join('/'),
          :build_path => File.join(manifest[:build_root], 'source', entry[:filename]),
          :url => [manifest[:url_root], 'source', entry[:filename]].join("/"),
          :build_task => 'build:image',
          :entry_type => :image
      end

    end

    desc "scans for Handlebars templates and converts them to JavaScript"
    task :handlebars => %w(setup) do |task, env|
      manifest = env[:manifest]

      entries = manifest.entries.select do |e|
        e[:ext] == 'handlebars'
      end

      entries.each do |entry|
        entry = manifest.add_transform entry,
          :filename => ['source', entry[:filename]].join('/'),
          :build_path => File.join(manifest[:build_root], 'source', entry[:filename].ext('js')),
          :url => [manifest[:url_root], 'source', entry[:filename]].join("/"),
          :build_task => 'build:handlebars',
          :resource   => 'javascript',
          :entry_type => :javascript
      end
    end

    desc "adds a module_info.js entry for all deferred and prefetched modules"
    task :module_info => %w(setup) do |task, env|
      target   = env[:target]
      manifest = env[:manifest]
      config   = CONFIG

      # Populate module_info for all deferred_modules frameworks.
      # Add :debug_required and :test_required depending on
      # the build mode.
      debug = config[:load_debug]
      test = config[:load_tests]

      # find all of the modules required by this target
      targets = target.modules({ :debug => debug, :test => test, :theme => true })

      unless targets.size == 0

        source_paths = []

        targets.each do |target|
          m = target.manifest_for(manifest.variation)
          m.build!

          m.entries.each do |entry|
            # The entry may have been built directly; we need to make sure it was
            # staged because we check staging_path
            entry.stage!
            case entry[:entry_type]
            when :css
              source_paths << entry[:staging_path]
            when :javascript
              source_paths << entry[:staging_path]
            end
          end
        end

        manifest.add_entry 'module_info.js',
          :dynamic        => true, # required to get correct timestamp for cacheable_url
          :build_task     => 'build:module_info',
          :resource       => 'javascript',
          :entry_type     => :javascript,
          :composite      => true,
          :target         => target,
          :targets        => targets,
          :variation      => manifest.variation,
          :debug          => debug,
          :test           => test,
          :theme          => true,
          :source_paths   => source_paths
      end
    end

    task :module_info => :tests # IMPORTANT! to avoid JS including unit tests.

    desc "generates combined entries for CSS"
    task :chance => %w(setup images javascript module_info css sass less) do |task, env|
      config = CONFIG
      manifest = env[:manifest]

      sprited = CONFIG[:use_sprites]
      minify = CONFIG[:minify_css]

      # the image files will be shared between all css_entries-- that is,
      # all instances of Chance created
      global_chance_entries = []

      # For each "resource" a separate css entry will be created.
      css_entries = {}

      manifest.entries.each do |entry|
        # Chance needs to know about image files so it can embed as data URIs in the
        # CSS. For this reason, if Chance is enabled, we need to send entries for image
        # files to the 'build:chance' buildtask.
        is_chance_file = ['.png', '.jpg', '.jpeg', '.gif'].include?(File.extname(entry[:filename]))

        next if entry[:resource].nil? and not is_chance_file

        if is_chance_file
          global_chance_entries << entry
        elsif entry[:entry_type] == :css
          (css_entries[entry[:resource]] ||= []) << entry
          entry.hide! if config[:combine_stylesheets]
        end

      end

      chance_instances = []
      all_chance_entries = []
      timestamps = []

      # We need a collection of source paths for our mhtml and JS files to
      # check mtimes against.
      source_paths = []

      # build combined CSS entry
      css_entries.each do |resource_name, entries|
        # Send image files to the build task if Chance is being used
        entries.concat global_chance_entries

        # We create the Chance Instance now, even though we don't run the whole thing.
        # This could incur a performance penalty to build manifests, but it is the only 
        # way to know what sprties, etc. need to be put into the manifest.
        #
        # Still, Chance has to get created sometime.
        chance = Chance::Instance.new({ :theme => CONFIG[:css_theme], :minify => CONFIG[:minify_css] })

        timestamp = 0
        has_2x_entries = false
        entries.each do |entry|
          timestamp = [entry.timestamp, timestamp].max

          # unfortunately, we have to stage the source entries NOW.
          src_path = entry.stage![:staging_path]
          next unless File.exist?(src_path)

          Chance.add_file src_path
          # Also remove source/ from the filename for sc_require and @import
          chance.map_file(entry.filename.sub(/^source\//, ''), src_path)

          has_2x_entries = true if src_path.include?("@2x")
        end

        timestamps << timestamp
        chance_instances << chance


        # ADD A 2X version
        # Because the @2x file is not a _real_ composite entry, and as such has
        # no true source entries (because we don't want to stage them as that
        # adversely impacts performance), we need to give a set of source paths
        # for the entry to compare mtimes with to know if it needs to update.
        entry_source_paths = entries.map {|e| e[:source_path] }

        add_chance_file = lambda {|entry_name, chance_file|
          manifest.add_entry entry_name,
            :variation       => manifest.variation,
            :build_task      => 'build:chance_file',
            :entry_type      => :css,
            :combined        => true,

            :source_entries  => entries,
            :ordered_entries => SC::Helpers::EntrySorter.sort(entries),

            :chance_file     => chance_file,
            :chance_instance => chance,

            # For cache-busting, we must support timestamped urls, but the entry
            # will be unable to calculate the timestamp for this on its own. So, we
            # must supply the calculated timestamp.
            :timestamp       => timestamp,

            :source_paths => entry_source_paths,
            :resource_name => resource_name,

            # So that modules, etc. can figure out what resource it belongs to
            :resource => resource_name,

            # Chance does minification on its own
            :minify => minify,

            # So that it can easily be recognized as an @2x entry.
            :x2 => entry_name.include?("@2x")
        }


        chance_file = "chance" + (sprited ? "-sprited" : "") + ".css"

        add_chance_file.call(resource_name + ".css", chance_file)

        # We only want to add the 2x version if there is a need for it.
        # NOTE: the HTML builder will need to pick the normal version if it
        # cannot find the @2x version.
        if has_2x_entries
          chance_2x_file = "chance" + (sprited ? "-sprited" : "") + "@2x.css"
          add_chance_file.call(resource_name + "@2x.css", chance_2x_file)
        end

        if sprited
          chance.sprite_names.each {|name|
            add_chance_file.call(resource_name + "-" + name, name);
          }

          chance.sprite_names({:x2 => true}).each {|name|
            add_chance_file.call(resource_name + "-" + name, name);
          }
        end

        # We also have a set of all source paths for the chance task. We need
        # to keep it up-to-date so that the MHTML and JS tasks can compare mtimes
        # with the entries.
        source_paths += entry_source_paths
        all_chance_entries += entries
      end

      if chance_instances.length > 0
        manifest.add_entry "__sc_chance.js",
          :build_task       => 'build:chance_file',
          :chance_instances   => chance_instances,
          :entry_type       => :javascript,
          :resource         => "javascript",
          :chance_file      => "chance.js",
          :timestamp        => timestamps.max,
          :source_paths     => source_paths,
          :source_entries   => all_chance_entries

        manifest.add_entry "__sc_chance_mhtml.txt",
          :build_task       => 'build:chance_file',
          :chance_instances   => chance_instances,
          :entry_type       => :mhtml,
          :chance_file      => "chance-mhtml.txt",
          :timestamp        => timestamps.max,
          :source_paths     => source_paths,
          :source_entries   => all_chance_entries
      end

    end

    desc "generates combined entries for javascript"
    task :combine => %w(setup chance javascript module_info) do |task, env|
      config = env[:target].config
      manifest = env[:manifest]
      config   = CONFIG

      javascript_entries = {}

      manifest.entries.each do |entry|
        # we can only combine entries with a resource property.
        next if entry[:resource].nil?

        if entry[:entry_type] == :javascript
          (javascript_entries[entry[:resource]] ||= []) << entry
        end
      end

      # build combined JS entry
      javascript_entries.each do |resource_name, entries|
        resource_name = resource_name.ext('js')

        if resource_name == 'javascript.js'
          pf = ['source/lproj/strings.js', 'source/core.js', 'source/utils.js']
          if manifest.target.target_type == :app
            target_name = manifest.target.target_name.to_s.split('/')[-1]
            pf.insert(2, "source/#{target_name}.js")
          end
        else
          pf = []
        end

        manifest.add_composite resource_name,
          :build_task      => 'build:combine',
          :source_entries  => entries,
          :top_level_lazy_instantiation => config[:lazy_instantiation],
          :hide_entries    => config[:combine_javascript],
          :ordered_entries => SC::Helpers::EntrySorter.sort(entries, pf),
          :entry_type      => :javascript,
          :combined        => true
      end
    end

    desc "Wraps the javascript.js file into a string if the target is a prefetched module"
    task :string_wrap => %w(setup css javascript module_info sass less combine minify) do |task, env|
      manifest = env[:manifest]
      target   = env[:target]

      next unless target[:target_type] == :module

      entry = manifest.entry_for "javascript.js"

      next if not entry
      transform = manifest.add_composite 'javascript-strings.js',
        :build_task     => 'build:string_wrap',
        :entry_type     => :javascript,
        :hide_entries   => false,
        :source_entries => [entry],
        :packed         => entry.packed? # carry forward
    end

    desc "adds a packed entry including javascript.js from required targets"
    task :packed => %w(setup combine) do |task, env|
      target   = env[:target]
      manifest = env[:manifest]

      # Only include a packed entry _if_ it is an app.
      if target[:target_type] == :app
        # Handle JavaScript version.  get all required targets and find their
        # javascript.js.  Build packed js from that.
        targets = target.expand_required_targets({ :theme => true }) + [target]
        entries = targets.map do |target|
          m = target.manifest_for(manifest.variation).build!

          # need to find the version that is not minified
          entry = m.entry_for('javascript.js')
          entry = entry.source_entry while entry && entry.minified?
          entry
        end

        entries.compact!
        manifest.add_composite 'javascript-packed.js',
          :build_task        => 'build:combine',
          :source_entries    => entries,
          :hide_entries      => false,
          :entry_type        => :javascript,
          :combined          => true,
          :ordered_entries   => entries, # orderd by load order
          :targets           => targets,
          :packed            => true

      end
    end

    task :minify => :packed # IMPORTANT: don't want minified version

    desc "adds a packed entry including stylesheet.css from required targets"
    task :packed => %w(setup combine) do |task, env|
      target   = env[:target]
      manifest = env[:manifest]

      # packed entries only for apps now.
      if target[:target_type] == :app

        %w(stylesheet stylesheet@2x).each {|resource|

          # Handle CSS version.  get all required targets and find their
          # stylesheet.css.  Build packed css from that.
          targets = target.expand_required_targets({ :theme => true }) + [target]
          entries = targets.map do |target|
            m = target.manifest_for(manifest.variation).build!

            # need to find the version that is not minified
            entry = m.entry_for(resource + ".css")
            entry = entry.source_entry while entry && entry.minified?
            entry
          end

          entries.compact!

          next if entries.length == 0
          manifest.add_composite resource + '-packed.css',
            :build_task        => 'build:combine',
            :source_entries    => entries,
            :hide_entries      => false,
            :entry_type        => :css,
            :combined          => true,
            :ordered_entries   => entries, # ordered by load order
            :targets           => targets,
            :packed            => true

        }
      end

    end

    task :minify => :packed # IMPORTANT: don't want minified version

    #Create builder tasks for sass and less in a DRY way
    [:sass, :less].each do |csscompiler|
      desc sprintf("create a builder task for all %s files to create css files", csscompiler.to_s)
      task csscompiler => :setup do |task, env|
        manifest = env[:manifest]

        manifest.entries.each do |entry|
          next unless entry[:ext] == csscompiler.to_s

          manifest.add_transform entry,
            :filename   => ['source', entry[:filename]].join('/'),
            :build_path => File.join(manifest[:build_root], 'source', entry[:filename]),
            :url => [manifest[:url_root], 'source', entry[:filename]].join("/"),
            :build_task => 'build:'+csscompiler.to_s,
            :entry_type => :css,
            :ext        => 'css',
            :resource   => 'stylesheet',
            :required   => []
        end
      end
    end

    desc "find all html-generating files, annotate and combine them"
    task :html => :setup do |task, env|
      target   = env[:target]
      manifest = env[:manifest]
      config   = CONFIG

      # select all entries with proper extensions
      known_ext = %w(rhtml erb haml)
      entries = manifest.entries.select do |e|
        (e[:entry_type] == :html) || (e[:entry_type].nil? && known_ext.include?(e[:ext]))
      end

      # tag entry with build directives and sort by resource
      entries_by_resource = {}

      entries.each do |entry|
        entry[:entry_type] = :html
        entry[:resource] = 'index'

        entry[:render_task] = case entry[:ext]
        when 'rhtml'
          'render:erubis'
        when 'erb'
          "render:erubis"
        when 'haml'
          'render:haml'
        end

        # items beginning with an underscore are partials.  do not build
        if entry[:filename] =~ /^_/
          entry.hide!
          entry[:is_partial] = true

        # not a partial
        else
          # use a custom scan method since discover_build_directives! is too
          # general...
          entry.scan_source(/<%\s*sc_resource\(?\s*['"](.+)['"]\s*\)?/) do |m|
            entry.resource = m[0].ext ''
          end
          (entries_by_resource[entry[:resource]] ||= []) << entry
        end
      end

      # even if no resource was found for the index.html, add one anyway if
      # the target is loadable
      if target.loadable? && entries_by_resource['index'].nil?
        entries_by_resource['index'] = []
      end

      # Now, build combined entry for each resource
      entries_by_resource.each do |resource_name, entries|
        resource_name = resource_name.ext('html')
        is_index = resource_name == 'index.html'

        # compute the friendly_url assuming normal install process
        friendly_url = [target[:index_root]]
        m_language = manifest[:language].to_sym
        t_preferred = (target.config[:preferred_language] || :en).to_sym
        if is_index
          friendly_url << m_language.to_s unless t_preferred == m_language
        else
          friendly_url << m_language.to_s
          friendly_url << resource_name
        end
        friendly_url = friendly_url.join('/')

        is_pref_lang = (manifest[:language] == config[:preferred_language])
        is_hidden = !target.loadable? && is_index
        overwrite_current = config[:overwrite_current]

        # index.html entries get generated three times.  Once for inside the
        # build dir, once for the language and once for the entire target name
        # Note that you must generate an index.html entry for all three even
        # if you won't actually use it because other index.html entries may
        # reference it
        (is_index ? 3 : 1).times do |rep_cnt|

          manifest.add_composite resource_name,
            :entry_type => :html,
            :combined => true,
            :build_task => 'build:html',
            :source_entries => entries, # make independent
            :hidden     =>  is_hidden,
            :include_required_targets => target.loadable? && is_index,
            :friendly_url => friendly_url,
            :is_index   => is_index

          # if this is the index, setup next rep
          if is_index
            resource_name = File.join('..', resource_name)
            is_hidden = true if !target.loadable? || !overwrite_current
            is_hidden = true if (rep_cnt>=2) && !is_pref_lang
          end
        end
      end
    end

    desc "creates transform entries for all css and Js entries to minify them if needed"
    task :minify => %w(setup javascript module_info css combine sass less) do |task, env|
      manifest = env[:manifest]
      config   = CONFIG

      minify_css = config[:minify_css]
      minify_css = config[:minify] if minify_css.nil?

      minify_javascript = config[:minify_javascript]
      minify_javascript = config[:minify] if minify_javascript.nil?

      manifest.entries.dup.each do |entry|
        case entry[:entry_type]
        when :css
          # NOTE: CSS MINIFICATION USING YUI MINIFIER IS CURRENTLY NOT WORKING.
          # But, since Chance is minifying it, we can disable this code path
          # for the moment. We'll need to add it back and fix YUI if we end up
          # supporting disabling Chance.
          # if minify_css
          #   manifest.add_transform entry,
          #     :build_task => 'build:minify:css',
          #     :entry_type => :css,
          #     :minified   => true,
          #     :packed     => entry.packed? # carry forward
          # end

        when :javascript
          if minify_javascript
            manifest.add_transform entry,
              :build_task => 'build:minify:javascript',
              :entry_type => :javascript,
              :minified   => true,
              :packed     => entry.packed? # carry forward
          end
        end
      end
    end

    desc "adds a loc strings entry that generates a yaml file server-side functions can use"
    task :strings => %w(setup javascript module_info) do |task, env|
      manifest = env[:manifest]

      # find the lproj/strings.js file...
      if entry = (manifest.entry_for('source/lproj/strings.js') || manifest.entry_for('source/lproj/strings.js', :hidden => true))
        manifest.add_transform entry,
          :filename   => 'strings.yaml',
          :build_path => File.join(manifest[:build_root], 'strings.yaml'),
          :staging_path => File.join(manifest[:staging_root], 'strings.yaml'),
          :url        => [manifest[:url_root], 'strings.yaml'].join('/'),
          :build_task => 'build:strings',
          :ext        => 'yaml',
          :entry_type => :strings,
          :hide_entry => false,
          :hidden     => true
      end
    end

    desc "..."
    task :image => :setup do
    end
  end
end
