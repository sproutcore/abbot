require File.expand_path(File.join(SC::LIBPATH, 'thor', 'lib', 'thor'))

module SC

  # The tools module contain the classes that make up the command line tools
  # available from SproutCore. In general, each command line tool has a peer
  # class hosted in this module that implements the primary user interface.
  #
  # Internally SproutCore tools that chain together subtools (such as 
  # sc-build) will actually call these classes directly instead of taking the
  # time to instantiate a whole new process. 
  #
  # Each Tool class is implemented as a Thor subclass.  You can override 
  # methods in these classes in your own ruby code if you want to make a 
  # change to how these tools execute.  Any ruby you place in your Buildfile
  # to modify one of these classes will actually be picked up by the 
  # tool itself when it runs.
  #
  class Tools < ::Thor
    
    ################################################
    ## GLOBAL OPTIONS 
    ##
    
    # All sproutcore tools can take some standard options.  These are 
    # processed automatically when the tool is loaded
    method_options({ '--project'        => :optional,
                     '--library'        => :optional, # deprecated
                     '--mode'           => :optional,
                     '--environment'    => :optional, # deprecated
                     '--logfile'        => :optional,
                     ['--verbose', '-v']      => false,
                     ['--very-verbose', '-V'] => false })
    def initialize(options, *args)
      super
    end
    
    def invoke(*args)
      require 'pp'
      pp options
      
      prepare_logger!
      prepare_mode!
      super
    end
      
    def options; @tool_options ||= HashStruct.new(super); end
    
    def prepare_logger!
      SC.env.log_level = options['very-verbose'] ? :debug : (options.verbose ? :info : :warn)
      SC.env.logfile = File.expand_path(options.logfile) if options.logfile
    end

    def prepare_mode!
      build_mode = options.mode || options.environment || :production
      SC.build_mode = build_mode
    end

    # Find the project...
    attr_reader :project
    def requires_project!
      
      ret = nil
      project_path = options.project || options.library
      if project_path.nil? # attempt to autodiscover
        SC.logger.debug "No project path specified.  Searching for projects in #{Dir.pwd}"
        ret = SC::Project.load_nearest_project Dir.pwd, :parent => SC.builtin_project
        if ret.nil?
          raise("You do not appear to be inside of a project.  Try changing to your project directory or make sure your project as a Buildfile or sc-config")
        end
      else
        SC.logger.debug "Project path specified at #{project_path}"
        ret = SC::Project.load File.expand_path(project_path), :parent => SC.builtin_project
        if ret.nil?
          raise "Could not load project at #{project_path}"
        end
      end
      
      SC.logger.debug "Loaded project at: #{ret.project_root}"
      @project = ret
    end
      
    # Find one or more targets with the passed target names
    def find_targets(*targets)
      requires_project!
      targets.map do |target_name|
        ret = project.target_for(target_name)
        if ret.nil?
          raise "No target named #{target_name} could be found in project"
        else
          SC.logger.debug "Found target '#{target_name}' at PROJECT:#{ret.source_root.sub(/^#{project.project_root}\//,'')}"
        end
        ret
      end
    end

    # Wraps around find_targets but raises an exception if no target is 
    # specified.
    def requires_targets!(*targets)
      targets = find_targets(*targets)
      if targets.size == 0
        raise "You must specify a target with this command" 
      end
      targets
    end
    
    # Finds one target.  This is just a convenience method wrapped around 
    # find_targets()
    def find_target(target); find_targets(target); end

    # Requires exactly one target.
    def requires_target!(*targets)
      requires_targets!(*targets).first
    end
    
    # Fix start so that it treats command-name like command_name
    def self.start(args = ARGV)
      # manually check for verbose in case we don't get far enough in regular
      # processing to actually set the verbose mode.
      is_verbose = %w(-v -V --verbose --very-verbose).any? { |x| args.include?(x) }
      begin
        super(args)
      rescue Exception => e
        SC.logger.fatal(e)
        if is_verbose
          SC.logger.fatal("BACKTRACE:\n#{e.backtrace.join("\n")}\n")
        end
        exit(1)
      end
    end
    
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
