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
          buildfile.execute_task 'target:prepare', 
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
    # === Returns
    #  Array of Targets
    #
    def required_targets
      @required_targets ||= [config.required || []].flatten.compact.map { |target_name| target_for(target_name) }.compact
    end

    # Returns the expanded list of required targets, ordered as they actually
    # need to be loaded.
    def expand_required_targets
      _expand_required_targets([self])
    end
    
    def _expand_required_targets(seen)
      ret = []
      required_targets.each do |target|
        next if seen.include?(target)
        seen << target # avoid loading again
        
        # add required targets, if not already seend...
        target._expand_required_targets(seen).each do |required|
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
    def compute_build_number(seen=nil)
      
      # Use config build number specifically for this target, if specified
      build_number = config.build_number

      # Otherwise, look for a global build_numbers hash and try that
      if build_number.nil? && (build_numbers = config.build_numbers)
        build_number = build_numbers[target_name.to_s] || build_numbers[target_name.to_sym]
      end

      # Otherwise, actually compute a build number. 
      if build_number.nil?
        require 'digest/md5'

        # No predefined build number was found, instead let's compute it!
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
        required_targets.each do |ct|
          next if seen.include?(ct)
          seen << ct
          digests << (ct.build_number || ct.compute_build_number(seen))
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
    
  end
  
end
