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
    ## EXCEPTIONS
    ##
    
    # Raise this type of exception when a fatal error occurs because the
    # user did not pass the correct options.  This will be caught and 
    # displayed at the top level before exiting.  Note that if you raise 
    # an exception of some other type, then a backtrace may be displayed as 
    # well (Which is not preferred)
    class FatalException < Exception
    end
    
    # Helper method.  Call this when an acception occurs that is fatal due to
    # a problem with the user.
    def fatal!(description)
      raise FatalException, description
    end
    
    # Helper method.  Call this when you want to log an info message.  Logs to
    # the standard logger.
    def info(description)
      SC.logger.info(description)
    end
    
    # Helper method.  Call this when you want to log a debug message.
    def debug(description)
      SC.logger.debug(description)
    end
    
    # Log this when you need to issue a warning.
    def warn(description)
      SC.logger.warn(description)
    end
     
    
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
      build_mode = (options.mode || options.environment || 'production').to_s.downcase.to_sym
      SC.build_mode = build_mode
    end

    # Find the project...
    attr_accessor :project
    def requires_project!
      
      return @project unless @project.nil?
      
      ret = nil
      project_path = options.project || options.library
      if project_path.nil? # attempt to autodiscover
        debug "No project path specified.  Searching for projects in #{Dir.pwd}"
        ret = SC::Project.load_nearest_project Dir.pwd, :parent => SC.builtin_project
        if ret.nil?
          fatal!("You do not appear to be inside of a project.  Try changing to your project directory or make sure your project as a Buildfile or sc-config")
        end
      else
        debug "Project path specified at #{project_path}"
        ret = SC::Project.load File.expand_path(project_path), :parent => SC.builtin_project
        if ret.nil?
          fatal! "Could not load project at #{project_path}"
        end
      end
      
      info "Loaded project at: #{ret.project_root}"
      @project = ret
    end
      
    # Find one or more targets with the passed target names
    def find_targets(*targets)
      requires_project!
      targets.map do |target_name|
        ret = project.target_for(target_name)
        if ret.nil?
          fatal! "No target named #{target_name} could be found in project"
        else
          debug "Found target '#{target_name}' at PROJECT:#{ret.source_root.sub(/^#{project.project_root}\//,'')}"
        end
        ret
      end
    end

    # Wraps around find_targets but raises an exception if no target is 
    # specified.
    def requires_targets!(*targets)
      targets = find_targets(*targets)
      if targets.size == 0
        fatal! "You must specify a target with this command" 
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
        if is_verbose && !e.kind_of?(FatalException)
          SC.logger.fatal("BACKTRACE:\n#{e.backtrace.join("\n")}\n")
        end
      end
    end
    
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
