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
  module Tools
    
    # The Tool base class is inherited by most tools.  It automatically 
    # accepts a --project option, or otherwise tries to autodetect the
    # project.  
    class Tool < ::Thor

      map '-o' => 'output'
      map '-v' => 'verbose'
      map '-dd' => 'debug'
      
      # These are standard options you can merge in to support for the 
      # tool in general.
      method_options({ :verbose     => :boolean,  
                       :debug       => :boolean, 
                       :logfile     => :optional,
                       :mode        => :optional,
                       :environment => :optional })
                     
      def initialize(opts, *args)
        super
      end
      
      attr_accessor :target, :manifest, :entry

      def options
        @tool_options ||= HashStruct.new(super)
      end
      
      ######################################################
      # STANDARD OPTIONS SUPPORT
      #

      def invoke(*args)
        discover_build_mode
        discover_logger
        discover_build_numbers
        standard_options!(*args)
        super
      end

      # Set/restore the default build mode
      def self.default_build_mode(build_mode=nil)
        @build_mode = build_mode unless build_mode.nil?
        @build_mode || (self == Tool ? :debug : superclass.default_build_mode)
      end

      # Discovers the build mode from the passed options
      def discover_build_mode
        build_mode = options.mode || options.environment || self.class.default_build_mode || :debug
        SC.build_mode = build_mode.to_sym
        return self
      end

      # Prepares the logging options.
      #
      # === Returns
      #  self
      def discover_logger
        if options.debug
          SC.env.log_level = :debug
        else
          SC.env.log_level = options.verbose ? :info : :warn
        end
        SC.env.logfile = File.expand_path(options.logfile) if options.logfile
        return self
      end
      
      # Discovers any build numbers passed in the environment.
      #
      # === Returns
      #  self
      def discover_build_numbers
        return self if (numbers = options.build).nil? # nothing to do
        
        build_numbers = {}
        numbers.split(',').each do |key_code|
          target_name, build_number = key_code.split(':')
          if build_number.nil?
            SC.env.build_number = target_name
          else
            target_name = target_name.to_s.sub(/^([^\/])/,'/\1').to_sym
            build_numbers[target_name] = build_number
          end
        end
        SC.env.build_numbers = build_numbers if build_numbers.size > 0
      end
      
      # Override this method in your subclass if you have some standard 
      # options you want to process for all incoming commands.
      def standard_options!(*args)
      end
      
      def debug?; SC.env.log_level == :debug; end
      
      ######################################################
      # PROJECT SUPPORT
      #
      
      # Standard options needed to support finding a project.  Be sure to
      # call prepare_project
      PROJECT_OPTIONS = { :project     => :optional, 
                          :library     => :optional }  # deprecated
      
      # The current working project
      attr_accessor :project
      
      # Attempts to discover the current working project.  Unless you specify
      # otherwise, this will use either the passed project path or it will
      # walk up the current path looking for the top-level directory with
      # a Buildfile or looking for the first Buildfile with a "project" 
      # directive.
      #
      # === Options
      #  :use_option:: if true, respects command line.  default true
      #
      # === Returns
      #  self
      #
      def prepare_project(opts = {})
        return @project unless @project.nil?
        
        use_option = opts[:use_option].nil? ? true : opts[:use_option]
        ret = nil
        
        project_path = use_option ? (options.project || options.library) : nil
        if project_path.nil? # attempt to autodiscover
          ret = SC::Project.load_nearest_project Dir.pwd, :parent => SC.builtin_project
        else
          ret = SC::Project.load File.expand_path(project_path), :parent => SC.builtin_project
        end
        
        SC.logger.info "Loaded project at: #{ret.project_root}" if ret
        @project = ret
        return self
      end
      
      # Verifies that a project has been set.  If no project is set, it will
      # attempt to discover the project.  If that fails, then it will raise
      # an error and exit.
      # 
      # The options you pass pass through to prepare_project()
      #
      # === Returns
      #  self
      #
      def requires_project!(opts = {})
        if prepare_project(opts).project.nil?
          raise "You do not appear to be inside of a valid project.  Try changing to your project directory and try again.  If you are inside of your project, make sure you have a Buildfile or sc-config at the root level."
        end
        return self
      end

      ######################################################
      # TARGET SUPPORT
      #
      
      # The targets to work on
      attr_accessor :targets
      
      # Verifies that the target is set.  If you pass a target name, this will
      # first try to get the target from the project and set it.  Otherwise,
      # it will just check that a target has been set.
      #
      # === Returns 
      #   self
      def requires_targets!(*target_names)
        if target_names.size > 0
          prepare_project
          puts target_names.first
          @targets = target_names.map { |t| self.project.target_for(t) }
        end
        if self.targets.nil? || self.targets.size == 0
          raise "#{ target_names.size > 0 ? target_names.join(',') : 'No target' } could not be found in this project"
        end
        return self
      end


      ######################################################
      # INTERNAL SUPPORT
      #
      
      # Fix start so that it treats command-name like command_name
      def self.start(args = ARGV)

        is_verbose = args.include?('--verbose') || args.include?('-v')
        
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
  
end

SC.require_all_libs_relative_to(__FILE__)
