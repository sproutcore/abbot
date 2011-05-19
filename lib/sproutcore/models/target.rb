# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require 'json'
require 'fileutils'

module SC

  # Defines a build target in a project.  A build target is a component that
  # you might want to build separately such as an application or library.
  #
  # Targets make require other targets through their dependencies property.
  # The property should name the other targets using either a relative or
  # absolute target name.  An absolute target name begins with a forward
  # slash (i.e. /sproutcore), where a relative begins with the target name
  # itself.
  #
  # When you create a target you must pass at least the following two
  # parameters:
  #
  #  target_name:: the name of the target, must start with a forward-slash
  #  target_type:: a task namespace that can be used to invoke tasks for
  #    building the manifest and other commands
  #
  # In addition to the above required parameters, you may also pass options.
  # These options will be simply set on the target and may be used by the
  # build tasks.  At least two options, however, have special meaning and
  # they should be set at some point before the task is used:
  #
  #  project:: This should point to the project the owns the target.  If you
  #    create a target using the Project#add_target method, this will be set
  #    for you.
  #  source_root::  This should contain the absolute path to the source
  #    directory for the target.  If you do not set this option, then the
  #    Target will not be able to load a Buildfile you define.  It is not
  #    strictly necessary to set this option however, as some targets may be
  #    entirely synthesized from other sources.
  #
  class Target < HashStruct
    # WYCATS TODO: Can these be memoized?
    def source_root
      self[:source_root]
    end

    def project
      self[:project]
    end

    def initialize(target_name, target_type, opts={})
      # Add target_name & type of options so they can be enumerated as part
      # of the hash
      opts = opts.merge :target_name => target_name,
                        :target_type => target_type

      # Remove the project since we do not want to enumerate that as part of
      # the hash
      @project = opts.delete(:project)
      super(opts)
    end

    attr_reader :project

    def inspect
      "SC::Target(#{self[:target_name]})"
    end

    # Invoke this method to make sure the basic paths for the target have
    # been prepared.  This method is called on the target before it is
    # returned from any call target_for().  It will invoke the target:prepare
    # build task.
    #
    # You can call this method as often as you want; it will only execute
    # once.
    #
    # === Returns
    #  Target
    def prepare!
      if !@is_prepared
        @is_prepared = true
        if buildfile.task_defined? 'target:prepare'
          buildfile.invoke 'target:prepare',
            :target => self, :project => self.project, :config => self.config
        end
      end
      return self
    end

    # Used for unit testing
    def prepared?; @is_prepared || false; end

    ######################################################
    # CONFIG
    #

    # Returns the buildfile for this target.  The buildfile is a clone of
    # the parent target buildfile with any buildfile found in the current
    # target's source_root merged over top of it.
    #
    # === Returns
    #  Buildfile
    #
    def buildfile
      @buildfile ||= parent_target.buildfile.dup.for_target(self).load!(source_root)
    end

    # Returns the config for the current project.  The config is computed by
    # taking the merged config settings from the build file given the current
    # build mode, then merging any environmental configs (set in SC::env)
    # over the top.
    #
    # This is the config hash you should use to control how items are built.
    def config
      return @config ||= buildfile.config_for(self[:target_name], SC.build_mode).merge(SC.env)
    end

    # Clears the cached config, reloading it from the buildfile again.  This
    # is mostly used for unit testing.
    def reload_config!
      @config= nil
      @is_prepared = false
      prepare!
      return self
    end


    ######################################################
    ## COMPUTED HELPER PROPERTIES
    ##

    # Returns all of the targets required by this target.  This will use the
    # "required" config, resolving the target names using target_for().
    #
    # You may pass some additional options in which will select the set
    # of targets you want returned.
    #
    # === Options
    #  :debug:: if true, config.debug_required will be included
    #  :test::  if true, config.test_required will also be included
    #
    # === Returns
    #  Array of Targets
    #
    def required_targets(opts={})

      opts_design = $design_mode && (self.target_type == :app)

      # compute cache key for these options
      key = [:debug, :test, :theme].map do |k|
        opts[k] ? k : nil
      end
      key << :design if opts_design

      # make sure we update for changes in theme and required (commonly changed):
      key << config[:theme].to_s if config[:theme] and opts[:theme]
      key << config[:required].to_s if config[:required]

      key = key.compact.join('.')


      # Return cache value if found
      ret = (@required_targets ||= {})[key]
      return ret unless ret.nil?

      # else compute return value, respecting options
      ret = [config[:required], config[:inlined_modules]]
      if opts[:debug] && config[:debug_required]
        ret << config[:debug_required]
      end
      if opts[:test] && config[:test_required]
        ret << config[:test_required]
      end

      if opts_design && config[:design_required]
        ret << config[:design_required]
      end

      if opts[:theme] && self.loads_theme? && config[:theme]
        # verify theme is a theme target type - note that if no matching
        # target is found, we'll just let this go through so the standard
        # not found warning can show.
        t = target_for(config[:theme])
        if t && t[:target_type] != :theme
          SC.logger.warn "Target #{config[:theme]} was set as theme for #{self[:target_name]} but it is not a theme."
        else
          ret << config[:theme]
        end
      end

      ret = ret.flatten.compact.map do |n|
        if (t = target_for(n)).nil?
          SC.logger.warn "Could not find target #{n} that is required by #{self[:target_name]}"
        end
        t
      end
      ret = ret.compact.uniq

      if self[:target_type].eql? :app
        reqs = self.find_required_modules

        if reqs.empty?
          reqs = project.targets.values.select { |target| target[:target_type] == :module }

          reqs = reqs.select do |target|
            target[:target_name].to_s.match(/^\/?#{self[:target_name]}/)
          end

          ret = ret.concat(reqs)
        end
      end

      @required_targets[key] = ret
      return ret
    end

    # Returns the recursive list of required modules for this target.
    #
    # === Returns
    #  Array of targets
    #
    def find_required_modules(opts ={})
      _find_required_modules(opts, [self])
    end

    def _find_required_modules(opts, seen)
      ret = []
      modules(opts).each do |target|
        next if seen.include?(target)
        seen << target # avoid loading again

        # add required targets, if not already seend...
        target._find_required_modules(opts, seen).each do |required|
          ret << required
          seen << required
        end

        # then add my own target...
        ret << target
      end
      return ret.uniq.compact
    end

    # Returns all of the modules under this target.  This
    # will use the deferred_modules, prefetched_modules, and inlined_modules config
    # options from the Buildfile.
    #
    #
    # === Options
    #  :debug:: if true, config.debug_required will be included
    #  :test::  if true, config.test_required will also be included
    #
    # === Returns
    #  Array of Targets
    #
    def modules(opts={})
      # compute cache key for these options
      key = [:debug, :test, :theme].map do |k|
        opts[k] ? k : nil
      end
      key = key.compact.join('.')

      # Return cache value if found
      ret = (@modules ||= {})[key]
      return ret unless ret.nil?

      # Get the list of targets that should be treated as prefetched, deferred
      # or inline modules from the Buildfile
      prefetched_modules = config[:prefetched_modules]
      deferred_modules = config[:deferred_modules]
      inlined_modules = config[:inlined_modules]

      # else compute return value, respecting options
      ret = [deferred_modules, prefetched_modules, inlined_modules]
      return [] if ret.compact.empty?

      if prefetched_modules
        ret << find_dependencies_for_modules(prefetched_modules, opts, :prefetched_module)
      end

      if deferred_modules
        ret << find_dependencies_for_modules(deferred_modules, opts, :deferred_module)
      end

      if inlined_modules
        ret << find_dependencies_for_modules(inlined_modules, opts, :inlined_module)
      end

      if opts[:debug] && config[:debug_required]
        ret << config[:debug_required]
      end
      if opts[:test] && config[:test_required]
        ret << config[:test_required]
      end

      ret = ret.flatten.compact.map do |n|
        if (t = target_for(n)).nil?
          SC.logger.warn "Could not find target #{n} that is required by #{target_name}"
        end
        t
      end
      ret = ret.compact.uniq

      @modules[key] = ret
      return ret
    end

    # For each module in the modules array, set the 'type' property to true,
    # and return an array of their dependencies, one level deep.
    def find_dependencies_for_modules(modules, opts, type)
      # To match other SC things like :required, allow it to be a single item
      # as well as an array.
      modules = [modules].flatten.compact

      ret = []

      modules.each do |m|
        target = target_for(m)

        if target == nil
          SC.logger.warn "Could not find target #{m} that is required by #{self[:target_name]}"
          return
        end

        target[type] = true

        target.required_targets(opts).flatten.compact.each do |dependency|
          if dependency[:target_type] == :module
            ret << dependency[:target_name]
          end
        end
      end

      return ret
    end

    # Returns true if this target can load a theme.  Default returns true
    # only if the target_type == :app, but you can override this by setting
    # the value yourself.
    def loads_theme?;
      ret = self[:loads_theme]
      ret.nil? ? (self[:target_type] == :app) : ret
    end

    # Returns the expanded list of required targets, ordered as they actually
    # need to be loaded.
    #
    # This method takes the same options as required_targets to select the
    # targets to include.
    #
    # === Returns
    #  Array of targets
    #
    def expand_required_targets(opts ={})
      _expand_required_targets(opts, [self])
    end

    def _expand_required_targets(opts, seen)
      ret = []
      required_targets(opts).each do |target|
        next if seen.include?(target)
        seen << target # avoid loading again

        # add required targets, if not already seend...
        target._expand_required_targets(opts, seen).each do |required|
          ret << required
          seen << required
        end

        # then add my own target...
        ret << target
      end
      return ret.uniq.compact
    end

    # Returns true if the passed path appears to be a target directory
    # according to the target's current config.
    def target_directory?(path, root_path=source_root)
      path = path.sub /^#{Regexp.escape root_path}\//, ''
      config.target_names.find do |name|
        path.index(name.to_s) == 0
      end
    end

    # path to attr_cache file
    def file_attr_cache_path
      @file_attr_cache_path ||= (self[:cache_root] / '__file_attr_cache.yml')
    end

    # suspend writing the file cache out if needed
    def begin_attr_changes
      @attr_change_level = (@attr_change_level || 0)+1
    end

    # resume writing file cache out if needed
    def end_attr_changes
      @attr_change_level = (@attr_change_level || 0) - 1
      if @attr_change_level <= 0
        @attr_change_level = 0
        _write_file_attr_cache if @attr_cache_has_changes
      end
    end

    def _write_file_attr_cache
      if (@attr_change_level||0) > 0
        @attr_cache_has_changes = true

      else
        @attr_cache_has_changes = false
        if @file_attr_cache
          FileUtils.mkdir_p(File.dirname(file_attr_cache_path))
          fp = File.open(file_attr_cache_path, 'w+')
          fp.write @file_attr_cache.to_json
          fp.close
        end
      end

    end


    # returns or computes an attribute on a given file.  this will keep the
    # named attribute in a cache keyed against the mtime of the named path.
    # if the mtime matches, the cached value is returned.  otherwise, yields
    # to the passed block to compute again.
    def file_attr(attr_name, path, &block)

      # read cache from disk if needed
      if @file_attr_cache.nil? && File.exists?(file_attr_cache_path)
        begin
          @file_attr_cache = JSON.parse File.read(file_attr_cache_path)
        rescue JSON::ParserError
          # Unparseable, will be handled by the following conditional
        end

        # Sometimes the file is corrupted, in this case, clear the cache
        File.delete file_attr_cache_path unless @file_attr_cache
      end
      @file_attr_cache ||= {}

      path_root = (@file_attr_cache[path] ||= {})
      attr_info = (path_root[attr_name.to_s] ||= {})
      attr_mtime = attr_info['mtime'].to_i
      path_mtime = File.exists?(path) ? File.mtime(path).to_i : 0
      if attr_mtime.nil? || (path_mtime != attr_mtime)
        SC.logger.debug "MISS file_attr_cache:#{attr_name}: #{File.basename(path)} path_mtime=#{path_mtime} attr_mtime=#{attr_mtime}"

        value = attr_info['value'] = yield
        attr_info['mtime'] = path_mtime
        _write_file_attr_cache

      else
        value = attr_info['value']
      end

      return value
    end

    # Computes a unique build number for this target.  The build number is
    # gauranteed to change anytime the contents of any source file changes
    # or anytime the build number of a required target changes.  Although
    # this will generate long strings, it will automatically ensure that
    # resources are properly cached when deployed.
    #
    # Note that this method does NOT set the build_number on the receiver;
    # it just calculates a value and returns it.  You usually call this
    # method just to set the build_number on the target.
    #
    # === Returns
    #  A build number string
    #
    def compute_build_number(seen=nil, opts = {})

      # reset cache if forced to recompute
      build_number = nil if opts[:force]

      # Look for a global build_numbers hash and try that
      if (build_numbers = config[:build_numbers])
        build_number = build_numbers[self[:target_name].to_s] || build_numbers[self[:target_name].to_sym]
      end

      # Otherwise, use config build number specifically for this target, if
      # specified
      build_number ||= config[:build_number]

      # Otherwise, actually compute a build number.
      if build_number.nil?
        require 'digest/sha1'

        # Computes the build number based on the contents of the
        # files.  It is not as fast as using an mtime, but it will remain
        # constant from one machine to the next so it can be used when
        # deploying across multiple build machines, etc.
        begin_attr_changes
        digests = Dir.glob(File.join(source_root, '**', '*')).map do |path|
          file_attr(:digest, path) do
            allowed = File.exists?(path) && !File.directory?(path)
            allowed = allowed && !target_directory?(path)
            allowed ? Digest::SHA1.hexdigest(File.read(path)) : nil
          end
        end
        end_attr_changes

        digests.compact!

        # Get all required targets and add in their build number.
        # Note the "seen" variable passed here will avoid circular references
        # causing infinite loops.  Normally this should not be necessary, but
        # we put this here to gaurd against misconfigured projects
        seen ||= []

        _targets = required_targets(:theme => true).sort do |a,b|
          (a[:target_name]||'').to_s <=> (b[:target_name]||'').to_s
        end

        _targets.each do |ct|
          next if seen.include?(ct)
          ct.prepare!
          seen << ct
          digests << ct.compute_build_number(seen, :force => true)
        end

        # Finally digest the complete string - tada! build number
        build_number = Digest::SHA1.hexdigest(digests.join)
      end

      return build_number.to_s
    end

    ######################################################
    # MANIFEST
    #

    # An array of manifests for the target.  You can retrieve the manifest
    # for a particular variation using the method manifest_for().
    def manifests; @manifests ||= []; end

    # Returns the manifest matching the variation options.  If no matching
    # manifest can be found, a new manifest will be created and prepared.
    def manifest_for(variation={})
      ret = manifests.find { |m| m.has_options?(variation) }
      if ret.nil?
        ret = Manifest.new(self, variation)
        @manifests << ret
      end
      return ret
    end

    ######################################################
    # BUNDLE INFO
    #

    # Returns a HashStruct containg three keys:
    #  :requires => an array of target_name strings from required targets
    #  :css_urls => an array of CSS URLs for this target in ordered for loading
    #  :js_urls  => an array of JS URLs for this target in ordered for loading
    #
    # The info returned is computed based on the current SC.build_mode and
    # the target's config. For example, in :production mode with CSS and JS
    # packing enabled, stylesheet-packed.css and javascript-packed.css would
    # be returned, rather than individual entries.
    #
    # NOTE: If the target is pre-loaded, an empty HashStruct is returned. The
    # target_name must still be added, but we'll never use the actual contents
    # and don't need to waste bandwidth downloading it.
    def module_info(opts ={})
      if self[:target_type] == :app
        raise "module_info called on an app target"
      else

        # Majd: I added this because modules shouldn't have the debug_required
        # and test_required frameworks applied to them since a module shouldn't
        # require a framework if the module is either deferred or prefetched
        if self[:deferred_module] or self[:prefetched_module]
          opts[:debug] = false
          opts[:test] = false
        end

        # only go one-level deep, and drop all non-module targets
        requires = required_targets(opts).select {|target|
          target[:target_type] == :module
        }

        # Targets that aren't pre-loaded can't be packed together. That leaves
        # loading css and js individually and/or loading the combined or
        # minified css and js.
        combine_css = config[:combine_stylesheets]
        combine_js  = config[:combine_javascript]
        minify_css  = config[:minify_css]
        minify_css  = config[:minify] if minify_css.nil?
        minify_js   = config[:minify_javascript]
        minify_js   = config[:minify] if minify_js.nil?
        pack_css    = config[:use_packed]
        pack_js     = config[:use_packed]

        # sort entries...
        css_entries = {}
        javascript_entries = {}

        manifest_for(opts[:variation]).build!.entries.each do |entry|
          if entry[:resource].nil?
            entry[:resource] = ''
          end

          # look for CSS or JS type entries
          case entry[:entry_type]
          when :css
            (css_entries[entry[:resource]] ||= []) << entry
          when :javascript
            (javascript_entries[entry[:resource]] ||= []) << entry
          end
        end

        css_urls = []
        css_2x_urls = []

        # For CSS, we only care about two items: stylesheet and stylesheet@2x.
        css_entries.each do |resource_name, entries|
          # if it is not stylesheet, we do not care about it.
          next if not resource_name == "stylesheet"

          SC::Helpers::EntrySorter.sort(entries).each do |entry|
            _css_urls = css_urls
            _css_urls = css_2x_urls if entry[:x2]

            if minify_css && entry[:minified]
              _css_urls << entry.cacheable_url
            elsif pack_css && entry[:packed] && !entry[:minified]
              _css_urls << entry.cacheable_url
            elsif combine_css && entry[:combined] && !entry[:packed] && !entry[:minified]
              _css_urls << entry.cacheable_url
            elsif !entry[:combined] && !entry[:packed] && !entry[:minified]
              _css_urls << entry.cacheable_url
            end
          end
        end

        # If there are no 2x entries, we need to give it the non-2x variety.
        css_2x_urls = css_urls if css_2x_urls.length == 0

        js_urls = []
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

          SC::Helpers::EntrySorter.sort(entries, pf).each do |entry|
            if minify_js && entry[:minified]
              js_urls << entry.cacheable_url
            elsif pack_js && entry[:packed] && !entry[:minified]
              js_urls << entry.cacheable_url
            elsif combine_js && entry[:combined] && !entry[:packed] && !entry[:minified]
              js_urls << entry.cacheable_url
            elsif !entry[:combined] && !entry[:packed] && !entry[:minified]
              js_urls << entry.cacheable_url
            end
          end
        end

        SC::HashStruct.new({
          :requires => requires,
          :css_urls => css_urls,
          :css_2x_urls => css_2x_urls,
          :js_urls => js_urls
        })
      end
    end

    ######################################################
    # TARGET METHODS
    #

    # Finds the parent target for this target.  The parent target is the
    # target with a higher-level of hierarchy.
    #
    # For example, the parent of 'sproutcore/foundation' is 'sproutcore'
    #
    # If your target is a top-level target, then this will return the project
    # itself.  If your target does not yet belong to a project, this will
    # return nil
    #
    def parent_target
      return @parent_target unless @parent_target.nil?
      return nil if project.nil?
      tname = self[:target_name]
      while @parent_target.nil?
        tname = tname.to_s.sub(/\/[^\/]+$/,'')
        @parent_target = (tname.size>0) ? project.target_for(tname) : project
      end
      @parent_target
    end

    # Find a target relative to the receiver target.  If you pass a regular
    # target name, this method will start by looking for direct children of
    # the receiver, then it will move up the hierarchy, looking in the parent
    # target and on up until it reaches the top-level library.
    #
    # This 'scoped' search model allows you to next targets and then to
    # properly reference them.
    #
    # To absolutely reference a target (i.e. to name its part beginning from
    # the project root, begin with a forward-slash.)
    #
    # === Params
    #  target_name:: the name of the target
    #
    # === Returns
    #  found target or nil if no match could be found
    #
    def target_for(target_name)
      if target_name =~ /^\// # absolute target
        ret = project.target_for(target_name)
      else # relative target...

        # look for any targets that are children of this target
        ret = project.target_for([self[:target_name], target_name].join('/'))

        # Ask my parent target to look for the target, and so on.
        if ret.nil?
          ret = parent_target.nil? ? project.target_for(target_name) : parent_target.target_for(target_name)
        end
      end
      return ret
    end

    ######################################################
    # LANGUAGE HELPER METHODS
    #

    LONG_LANGUAGE_MAP = { :english => :en, :french => :fr, :german => :de, :japanese => :ja, :spanish => :es, :italian => :it }
    SHORT_LANGUAGE_MAP = { :en => :english, :fr => :french, :de => :german, :ja => :japanese, :es => :spanish, :it => :italian }

    # Returns the language codes for any languages actually found in this
    # target.
    def installed_languages
      ret = Dir.glob(File.join(source_root, '*.lproj')).map do |path|
        next unless path =~ /\/([^\/]+)\.lproj/
        (LONG_LANGUAGE_MAP[$1.downcase.to_sym] || $1).to_s
      end
      ret << config[:preferred_language].to_s if config[:preferred_language]
      ret.compact.uniq.sort { |a,b| a.downcase <=> b.downcase }.map { |l| l.to_sym }
    end

    # Returns project-relative path to the lproj directory for the named
    # short language code
    def lproj_for(language_code)

      # try code as passed
      ret = "#{language_code}.lproj"
      return ret if File.directory? File.join(source_root, ret)

      # try long language too...
      language_code = SHORT_LANGUAGE_MAP[language_code.to_s.downcase.to_sym]
      if language_code
        ret = "#{language_code}.lproj"
        return ret if File.directory? File.join(source_root, ret)
      end

      # None found
      return nil
    end

  end

end
