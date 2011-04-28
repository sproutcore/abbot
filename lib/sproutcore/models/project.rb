# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  # A project describes a collection of targets that you can build.  Normally
  # you instantiate a project by calling Project.load() method.  You should
  # pass in the path of the project and the project type.  The project type
  # will determine the namespace used in the buildfile to detect and load
  # tasks.
  #
  # == Examples
  #
  # Load a SproutCore-style project:
  #
  #  Project.load('myproject', :sproutcore)
  #
  # Load a standard gcc-build project:
  #
  #  Project.load('myproject', :cc)
  #
  # == How a Project is Loaded
  #
  # When you load a project, here is what happens:
  #
  # 1. Locate and load Buildfiles, if any are found
  # 2. Run project_type:target:find for all targets defined for the project.
  #    this will locate and define the targets for the project
  # 3. If you request a build of a particular resource, a manifest will be
  #    built for the target.  This manifest contains a series of rules that
  #    can be invoked in order to build the named resource.
  #
  class Project

    # the path of this project
    attr_reader :project_root

    # Parent project this project shoud inherit build rules and targets from
    attr_reader :parent_project
    
    # Proc that will be called when changes are detected to a monitored project
    attr_accessor :monitor_proc
    
    # regex so that certain files don't trigger monitor update
    attr_accessor :nomonitor_pattern

    def inspect
      "SC::Project(#{File.basename(project_root || '')})"
    end

    # When a new project is created, you may optionally pass either a
    # :parent option or a :paths options.  If you pass the paths option, then
    # this class will search the paths for projects and initialize them as
    # parent projects to this one.
    #
    # If you pass a parent project, then this project will start out with a
    # clone of the parent project's buildfile and targets.
    #
    def initialize(project_root, opts ={})
      @project_root = project_root
      @parent_project = opts[:parent]
      @buildfile = @targets = nil
    end

    # Attempts to find the nearest project root
    def self.load_nearest_project(path, opts={})
      candidate = nil
      while path
        if Buildfile.has_buildfile?(path)
          candidate = path

          # If we find a buildfile and the buildfile explicitly states
          # that it is a project, then just stop here..
          break if Buildfile.load(path).project?
        end

        new_path = File.dirname(path)
        path = (new_path == path) ? nil : new_path
      end
      (candidate) ? self.new(candidate, opts) : nil
    end

    # Returns a new project loaded from the specified path
    def self.load(project_root, opts={})
      new project_root, opts
    end

    def reload!
      @buildfile = @targets = nil
    end

    # The current buildfile for the project.  The buildfile is calculated by
    # merging any parent project buildfile with the contents of any
    # buildfiles found in the current project.  Buildfiles include any file
    # named "Buildfile", "sc-config", or "sc-config.rb".  You can also
    # specify your own buildfile names with the "buildfile_names" config in
    # the SC.env.
    #
    # === Returns
    #  Buildfile instance
    #
    def buildfile
      @buildfile ||= (parent_project.nil? ? Buildfile.new : parent_project.buildfile.dup).load!(project_root)
    end

    # The config for the current project.  The config is computed by merging
    # the config settings from the current buildfile and then the current
    # environment in the following order:
    #
    #  config for all modes, all targets +
    #  config for current mode, all targets +
    #  Current environment defined in SC.env
    #
    # This is the config hash you should access to determine general project
    # wide settings that cannot be overridden by individual targets.
    #
    # === Returns
    #  merged HashStruct
    #
    def config
      return @config ||= buildfile.config_for(:all, SC.build_mode).merge(SC.env)
    end

    ################################################
    ## TARGETS
    ##

    # A hash of the known targets for this project, including any targets
    # inherited from a parent project.  Each target is stored in the hash
    # by target_name.
    #
    # The first time this method is called, the project will automatically
    # clone any targets from a parent project, and then calls
    # find_targets_for() on itself to recursively discover any targets in
    # the project.
    #
    # If you need to change the way the project discovers project, override
    # find_targets_for() instead of this method.
    #
    # === Returns
    #  Hash of targets keyed by target_name
    #
    def targets
      return @targets unless @targets.nil?

      # Create an empty targets hash or clone from parent project
      @targets = HashStruct.new
      dup_targets(parent_project.targets) if parent_project

      # find targets inside project.
      find_targets_for(project_root, nil, self.config)

      return @targets
    end

    # Returns the target with the specified target name.  The target name
    # may be absolute path or not, both will lookup from the top.
    #
    # === Params
    #  target_name:: the target to lookup
    #
    # === Returns
    #  a Target instance or nil if no matching target could be found
    #
    def target_for(target_name)
      ret = (targets[target_name.to_s.sub(/^([^\/])/,'/\1').to_sym])
      ret.nil? ? nil : ret
    end

    # Adds a new target to the project with the passed target name.  Include
    # the source_root for the target as well as any additional options you
    # want copied onto the target.  If a previous target was defined by the
    # same name it will be replaced by this one.
    #
    # === Params
    #  target_name:: the name of the target.
    #  target_type:: the type of target
    #
    # === Options (any others allowed also)
    #  source_root:: the absolute path to the target source
    #
    # === Returns
    #  new target
    #
    def add_target(target_name, target_type, options={})
      targets[target_name.to_sym] = Target.new(target_name.to_sym,
          target_type.to_sym, options.merge(:project => self))
    end

    # Called by project to discover any targets within the project itself.
    # The default implementation will search the project root directory for
    # any directories matching those named in the "target_types" config. (See
    # Buildfile for documentation).  It will then recursively descend into
    # each target looking for further nested targets unless you've set the
    # "allow_nested_targets" config to false.
    #
    # If you need to change the way the project autodiscovers its own targets
    # you can either change the "target_types" and "allow_nested_targets"
    # configs or you can override this method in your own ruby code to
    # do whatever kind of changes you want.
    #
    # === Params
    #  root_path:: The path to search for targets.
    #  root_name:: The root target name
    #  config::    The config hash to use for this.  Should come from target
    #
    # === Returns
    #  self
    #
    def find_targets_for(root_path, root_name, config)

      # look for directories matching the target_types keys and create target
      # with target_types value as type. -- normalize to lowercase string
      target_types = {}
      (config[:target_types] || {}).each do |key, value|
        target_types[key.to_s.downcase] = value
      end

      # look for directories matching a target type
      Dir.glob(File.join(root_path, '*')).each do |dir_name|
        target_type = target_types[File.basename(dir_name).to_s.downcase]
        next if target_type.nil?
        next unless File.directory?(dir_name)

        # loop through each item in the directory.
        Dir.glob(File.join(dir_name,'*')).each do |source_root|
          next unless File.directory?(source_root)

          # compute target name and create target
          target_name = [root_name, File.basename(source_root)] * '/'
          target = self.add_target target_name, target_type,
            :source_root => source_root

          # if target's config allows nested targets, then call recursively
          # asking the target's config allows the target's Buildfile to
          # override the default.
          if target.config[:allow_nested_targets]
            find_targets_for(source_root, target_name, target.config)
          end
        end # Dir.glob
      end # target_type.each
      return self
    end

    ################################################
    ## GENERATOR SUPPORT
    ##

    # Attempts to discover and load a generator with the specified name from
    # the current project.  If the generator cannot be found, this method will
    # return nil.
    def generator_for(generator_name, opts={})
      opts[:target_project] = self
      return SC::Generator.load(generator_name, opts)
    end

    private

    # Loops through the hash of targets and adds them to the receiver.  This
    # is how we inherit inherit targets from a parent project.
    def dup_targets(to_dup)
      to_dup.each do | target_name, target |
        add_target target_name, target[:target_type], target.to_hash
      end
    end

  end

end
