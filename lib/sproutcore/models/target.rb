# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

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
      "SC::Target(#{target_name})"
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
      @buildfile ||= parent_target.buildfile.dup.for_target(self).load!(self.source_root)
    end
    
    # Returns the config for the current project.  The config is computed by 
    # taking the merged config settings from the build file given the current
    # build mode, then merging any environmental configs (set in SC::env)
    # over the top.
    #
    # This is the config hash you should use to control how items are built.
    def config
      return @config ||= buildfile.config_for(target_name, SC.build_mode).merge(SC.env)
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
      
      # compute cache key for these options
      key = [:debug, :test, :theme].map do |k| 
        opts[k] ? k : nil 
      end
      key = key.compact.join('.')
      
      # Return cache value if found
      ret = (@required_targets ||= {})[key]
      return ret unless ret.nil?
      
      # else compute return value, respecting options
      ret = [config.required]
      if opts[:debug] && config.debug_required
        ret << config.debug_required 
      end
      if opts[:test] && config.test_required
        ret << config.test_required
      end 
      if opts[:theme] && self.loads_theme? && config.theme
        # verify theme is a theme target type - note that if no matching
        # target is found, we'll just let this go through so the standard
        # not found warning can show.
        t = target_for(config.theme)
        if t && t.target_type != :theme
          SC.logger.warn "Target #{config.theme} was set as theme for #{target_name} but it is not a theme."
        else
          ret << config.theme
        end
      end
      
      ret = ret.flatten.compact.map do |n| 
        if (t = target_for(n)).nil? 
          SC.logger.warn "Could not find target #{n} that is required by #{target_name}"
        end
        t
      end
      ret = ret.compact.uniq

      @required_targets[key] = ret
      return ret 
    end
    
    # Returns all of the targets dynamically required by this target.  This 
    # will use the "dynamic_required" config, resolving the target names using
    # target_for().
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
    def dynamic_required_targets(opts={})
      
      # compute cache key for these options
      key = [:debug, :test, :theme].map do |k| 
        opts[k] ? k : nil 
      end
      key = key.compact.join('.')
      
      # Return cache value if found
      ret = (@dynamic_targets ||= {})[key]
      return ret unless ret.nil?
      
      # else compute return value, respecting options
      ret = [config.dynamic_required]
      if opts[:debug] && config.debug_dynamic_required
        ret << config.debug_dynamic_required
      end
      if opts[:test] && config.test_dynamic_required
        ret << config.test_dynamic_required
      end 
      if opts[:theme] && self.loads_theme? && config.theme
        # verify theme is a theme target type - note that if no matching
        # target is found, we'll just let this go through so the standard
        # not found warning can show.
        t = target_for(config.theme)
        if t && t.target_type != :theme
          SC.logger.warn "Target #{config.theme} was set as theme for #{target_name} but it is not a theme."
        else
          ret << config.theme
        end
      end
      
      ret = ret.flatten.compact.map do |n| 
        if (t = target_for(n)).nil? 
          SC.logger.warn "Could not find target #{n} that is required by #{target_name}"
        end
        t
      end
      ret = ret.compact.uniq
      
      @dynamic_targets[key] = ret
      return ret 
    end
    
    # Returns true if this target can load a theme.  Default returns true 
    # only if the target_type == :app, but you can override this by setting
    # the value yourself.
    def loads_theme?;
      ret = self[:loads_theme]
      ret.nil? ? (target_type == :app) : ret
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
    def target_directory?(path, root_path=nil)
      root_path = self.source_root if root_path.nil?
      @target_names ||= self.config.target_types.keys
      path = path.to_s.sub /^#{Regexp.escape root_path}\//, ''
      @target_names.each do |name|
        return true if path =~ /^#{Regexp.escape name.to_s}/
      end
      return false
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
      if (build_numbers = config.build_numbers)
        build_number = build_numbers[target_name.to_s] || build_numbers[target_name.to_sym]
      end

      # Otherwise, use config build number specifically for this target, if 
      # specified
      build_number ||= config.build_number 

      # Otherwise, actually compute a build number. 
      if build_number.nil?
        require 'digest/sha1'

        # Computes the build number based on the contents of the
        # files.  It is not as fast as using an mtime, but it will remain
        # constant from one machine to the next so it can be used when
        # deploying across multiple build machines, etc.
        digests = Dir.glob(File.join(source_root, '**', '*')).map do |path|
          allowed = File.exists?(path) && !File.directory?(path)
          allowed = allowed && !target_directory?(path)
          allowed ? Digest::SHA1.hexdigest(File.read(path)) : nil
        end
        digests.compact!

        # Get all required targets and add in their build number.
        # Note the "seen" variable passed here will avoid circular references
        # causing infinite loops.  Normally this should not be necessary, but
        # we put this here to gaurd against misconfigured projects
        seen ||= []
        
        _targets = required_targets(:theme => true).sort do |a,b|
          (a.target_name||'').to_s <=> (b.target_name||'').to_s
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
    def bundle_info(opts ={})
      if target_type == :app
        raise "bundle_info called on an app target"
      else
        requires = required_targets(opts) # only go one-level deep!
        
        # Targets that aren't pre-loaded can't be packed together. That leaves
        # loading css and js individually and/or loading the combined or 
        # minified css and js.
        combine_css = config.combine_stylesheets
        combine_js  = config.combine_javascript
        minify_css  = config.minify_css
        minify_css  = config.minify if minify_css.nil?
        minify_js   = config.minify_javascript
        minify_js   = config.minify if minify_js.nil?
        pack_css    = config.use_packed
        pack_js     = config.use_packed
        
        # sort entries...
        css_entries = {}
        javascript_entries = {}
         manifest_for(opts[:variation]).build!.entries.each do |entry|
          if entry.resource.nil?
            entry.resource = ''
          end
          
          # look for CSS or JS type entries
          case entry.entry_type
          when :css
            (css_entries[entry.resource] ||= []) << entry
          when :javascript
            (javascript_entries[entry.resource] ||= []) << entry
          end
        end
        
        css_urls = []
        css_entries.each do |resource_name, entries|
          SC::Helpers::EntrySorter.sort(entries).each do |entry|
            if minify_css && entry.minified
              css_urls << entry.cacheable_url
            elsif pack_css && entry.packed && !entry.minified
              css_urls << entry.cacheable_url
            elsif combine_css && entry.combined && !entry.packed && !entry.minified
              css_urls << entry.cacheable_url
            elsif !entry.combined && !entry.packed && !entry.minified
              css_urls << entry.cacheable_url
            end
          end
        end
        
        js_urls = []
        javascript_entries.each do |resource_name, entries|
          resource_name = resource_name.ext('js')
          pf = (resource_name == 'javascript.js') ? %w(source/lproj/strings.js source/core.js source/utils.js) : []
          SC::Helpers::EntrySorter.sort(entries, pf).each do |entry|
            if minify_js && entry.minified
              js_urls << entry.cacheable_url
            elsif pack_js && entry.packed && !entry.minified
              js_urls << entry.cacheable_url
            elsif combine_js && entry.combined && !entry.packed && !entry.minified
              js_urls << entry.cacheable_url
            elsif !entry.combined && !entry.packed && !entry.minified
              js_urls << entry.cacheable_url
            end
          end
        end
        
        SC::HashStruct.new :requires => requires, :css_urls => css_urls, :js_urls => js_urls
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
      tname = target_name
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
        ret = project.target_for([self.target_name, target_name].join('/'))
        
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
      ret << config.preferred_language.to_s if config.preferred_language
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

    ######################################################
    # BUILD DOCS METHODS
    #

    # Creates all of the documentation for the target.
    # 
    # === Options
    #
    #  :build_root:: the root path to place built documentation
    #  :language::   the language to build.  defaults to preferred lang
    #  :required::   include required targets.  defaults to true
    def build_docs!(opts ={})

      build_root   = opts[:build_root] || nil
      language     = opts[:language] || self.config.preferred_language || :en
      logger       = opts[:logger] || SC.logger
      template_name = opts[:template] || 'sproutcore'
      use_required = opts[:required]
      use_required = true if use_required.nil? 
      
      # collect targets to build
      doc_targets = [self]
      doc_targets = (self.expand_required_targets + [self]) if use_required

      # convert targets to manifests so we can get alll files
      doc_manifests = doc_targets.map do |target| 
        target.manifest_for(:language => language)
      end

      # Collect all source entries, in the order they should be loaded
      file_list = []
      doc_manifests.each do |manifest|
        entry = manifest.build!.entry_for('javascript.js')
        next if entry.nil?

        # loop over entries, collecting their source entries until we get
        # back to the original source files.  Since we expand these entries
        # in their proper load order this should give us something suitable
        # to hand to jsdoc.
        entries = entry.ordered_entries || entry.source_entries
        while entries && entries.size>0
          new_entries = []
          entries.each do |cur_entry|
            sources = cur_entry.ordered_entries || cur_entry.source_entries
            if sources
              new_entries += sources
            elsif entry.filename =~ /\.js$/
              file_list << cur_entry.source_path
            end
          end
          entries = new_entries
        end
      end

      file_list = file_list.uniq # remove duplicates
      file_list = file_list.select { |path| File.exist?(path) }

      logger.info "Building #{target_name} docs at #{build_root}"
      FileUtils.mkdir_p(build_root)

      # Prepare jsdoc opts
      jsdoc_root    = SC::PATH / 'vendor' / 'jsdoc'
      jar_path      = jsdoc_root / 'jsrun.jar'
      runjs_path    = jsdoc_root / 'app' / 'run.js'
      
      # look for a directory matching the template name
      cur_project = self.project
      has_template = false
      while cur_project 
        template_path = cur_project.project_root / 'doc_templates' / template_name
        has_template = File.directory?(template_path)
        cur_project = has_template ? nil : cur_project.parent_project
      end

      if !has_template
        cur_project = self.project
        has_template = false
        while cur_project 
          template_path = cur_project.project_root / template_name
          has_template = File.directory?(template_path)
          cur_project = has_template ? nil : cur_project.parent_project
        end
      end
      throw("could not find template named #{template_name}") if !has_template

      # wrap files in quotes...
      # Note: using -server gives an approx. 25% speed boost over -client 
      # (the default)
      js_doc_cmd = %(java -server -Djsdoc.dir="#{jsdoc_root}" -jar "#{jar_path}" "#{runjs_path}" -t="#{template_path}" -d="#{build_root}" "#{ file_list * '" "' }" -v)

      logger.info "File Manifest:\r\n"
      file_list.each { |file_path| logger.info(file_path) }
      
      puts "Generating docs for #{self.target_name}\r\nPlease be patient this could take awhile..."
      
      # use pipe so that we can immediately log output as it happens
      IO.popen(js_doc_cmd) do |pipe|
        while line = pipe.gets
          next if line =~ /WARNING: (<|===|index:)/
          logger.info line.sub(/\n$/,'')
        end
      end

      puts "Finished."
    end
    
  end
  
end
