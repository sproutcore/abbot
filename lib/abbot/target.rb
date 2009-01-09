module Abbot
  
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
    # build mode, then merging any environmental configs (set in Abbot::env)
    # over the top.
    #
    # This is the config hash you should use to control how items are built.
    def config
      return @config ||= buildfile.config_for(target_name, Abbot.build_mode).merge(Abbot.env)
    end

    # An array of manifests for the target.  You can retrieve the manifest
    # for a particular variation using the method manifest_for().
    def manifests; @manifests ||= []; end
    
    # Returns the manifest matching the variation options.  If no matching
    # manifest can be found, a new manifest will be created and prepared.
    def manifest_for(variation={})
      ret = manifests.find { |m| m.has_options?(variation) }
      if ret.nil?
        ret = Manifest.new(variation.merge(:target => self)).prepare!
        @manifests << ret
      end
      return ret 
    end
    
    ########################################################################
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
        
  end
  
end
