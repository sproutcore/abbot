module Abbot
  
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
  # 1. Kocate and load Buildfiles, if any are found
  # 2. Run project_type:target:find for all targets defined for the project.  
  #    this will locate and define the targets for the project
  # 3. If you request a build of a particular resource, a manifest will be
  #    built for the target.  This manifest contains a series of rules that
  #    can be invoked in order to build the named resource.
  #
  class Project
    
    # Default buildfile names.  Override with Abbot.env.buildfile_names
    BUILDFILE_NAMES = %w(Buildfile sc-config sc-config.rb)
    
    # the path of this project
    attr_reader :project_path
    
    # Parent project this project shoud inherit build rules and targets from
    attr_reader :parent_project 
    
    # When a new project is created, you may optionally pass either a 
    # :parent option or a :paths options.  If you pass the paths option, then
    # this class will search the paths for projects and initialize them as
    # parent projects to this one.
    #
    # If you pass a parent project, then this project will start out with a
    # clone of the parent project's buildfile and targets.
    #
    def initialize(project_path, opts ={})
      @project_path = project_path
      @parent_project = opts[:parent]
      @buildfile = @targets = nil
    end

    def self.load(project_path, opts={})
      new project_path, project_type, opts
    end

    # Retrieves the current buildfile for the project.  If the project has
    # a parent_project, the parent's buildfile will be used as the basis for
    # this buildfile.
    #
    # This method will look for any buildfiles matching the 
    # buildfile_names environment and load, in order.
    def buildfile
      return @buildfile unless @buildfile.nil?
      
      # get base buildfile
      @buildfile = parent_project.nil? ? Buildfile.new : parent_project.buildfile.dup
      
      # Look for any buildfiles matching the buildfile names and load them
      (Abbot.env.buildfile_names || BUILDFILE_NAMES).each do |filename|
        filename = File.join(project_path, filename)
        next unless File.exist?(filename) && !File.directory?(filename)
        @buildfile.load!(filename)
      end
      return @buildfile
    end

    # Returns the config for the current project.  The config is computed by 
    # taking the merged config settings from the build file given the current
    # build mode, then merging any environmental configs (set in Abbot::env)
    # over the top.
    #
    # This is the config hash you should use to control how items are built.
    def config
      return @config ||= buildfile.config_for(:all, Abbot.build_mode).merge(Abbot.env)
    end

    # Retrieves a hash of all the targets known to this project, including
    # those targets that are owned by the parent project.  The first time you
    # call this method, it will get the targets from the parent and then it 
    # will ask the buildfile to find any targets.
    def targets
      return @targets unless @targets.nil?
      
      # Create an empty targets hash or clone from parent project
      @targets = HashStruct.new
      dup_targets(parent_project.targets) if parent_project

      # Ask buildfile to find all targets for self.
      buildfile.execute_task('abbot:find_targets', :project => self, :config => self.config) rescue nil
      
      return @targets
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
    #  self
    #
    def add_target(target_name, target_type, options={})
      targets[target_name] = Target.new(target_name.to_sym, 
          target_type.to_sym, options.merge(:project => self))
      return self
    end
    
    private 
    
    # Loops through the hash of targets and adds them to the receiver.  This
    # is how we inherit inherit targets from a parent project.
    def dup_targets(to_dup)
      to_dup.each do | target_name, target |
        add_target target.target_name, target
      end
    end
    
  end
  
end


  