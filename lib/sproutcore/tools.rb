require 'thor'

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
      map '-vv' => 'verbose'
      
      attr_accessor :target, :manifest, :entry
      
      def verbose?; options['verbose'] || false; end
      
      def project 
        return @project unless @project.nil?
        project_path = options['project']
        if project_path.nil? 
          @project = SC::Project.load_nearest_project Dir.pwd, 
            :parent => SC.builtin_project
        else
          @project = SC::Project.load File.expand_path(project_path), 
            :parent => SC.builtin_project
        end
        
        puts("~ Loaded project at: #{@project.project_root}") if verbose? && @project
        
        return @project
      end
      attr_writer :project
      
      # Verifies that a project could be created.  If you pass an option, it
      # should be the project you want to set.  If the new project value is
      # nil, then this will raise a standard error.
      def requires_project!
        if project.nil?
          raise "You do not appear to be inside a valid project.  Try changing to your project directory and try again.  If you are inside your project directory, make sure you have a Buildfile or sc-config installed as well."
        end
        return project
      end
      
      # Verifies that the target is set.  If you pass a target name, this will
      # first try to get the target from the project and set it.  Otherwise,
      # it will just check.
      def requires_target!(target_name=nil)
        if target_name
          requires_project!
          @target = project.target_for(target_name)
        end
        if self.target.nil?
          raise "Target #{target_name} could not be found in this project"
        end
        return self.target
      end
      
      # Fix start so that it treats command-name like command_name
      def self.start(args = ARGV)
        args = args.dup
        args[0] = args[0].gsub('-','_') if args.size>0

        is_verbose = args.include?('--verbose') || args.include?('-vv')
        
        begin
          super(args)
        rescue Exception => e
          STDERR << "ERROR: " << e << "\n\n"
          STDERR << "========\n#{e.backtrace.join("\n")}\n" if is_verbose
          exit(1)
        end
      end
      
      def logger; @logger = ::Logger.new; end
      
    end
    
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
