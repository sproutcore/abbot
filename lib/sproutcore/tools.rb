# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

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
  class Tools < ::Thor
    check_unknown_options!

    def self.invoke(task_name)
      start([task_name.to_s] + ARGV)
    end

    # All sproutcore tools can take some standard options.  These are
    # processed automatically when the tool is loaded
    class_option "project",      :type => :string
    class_option "mode",         :type => :string
    class_option "logfile",      :type => :string
    class_option "build",        :type => :string, :aliases => "-b"
    class_option "build-targets",:type => :string,
      :desc => "Targets to build (excluding their dependencies)"

    class_option "dont-minify",     :type => :boolean,
      :desc => "Disables minification for the build."

    class_option "verbose",      :type => :boolean, :aliases => "-v"
    class_option "very-verbose", :type => :boolean, :aliases => "-V"

    class_option "help",         :type => :boolean

    default_task :banner

    desc "help", "How to use the sproutcore command"
    def banner
      str = "SproutCore #{SC::VERSION} Usage"
      puts "#{str}\n"+('='*str.length)+"\n\n"

      help
    end

    map "--version" => :version
    desc "version", "Show the SproutCore version number"
    def version
      puts "SproutCore #{SC::VERSION}"
    end

    # This is the core entry method used to run every tool.  Extend this
    # method with any standard preprocessing you want all tools to do before
    # they do their specific thing.
    def initialize(*)
      super
      prepare_logger!
      prepare_mode!
      dont_minify!
      prepare_app!
      prepare_build_numbers!
    end

    no_tasks do

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

      # Helper method.  Call this when an acception occurs that is fatal due
      # to a problem with the user.
      def fatal!(description)
        raise FatalException, description
      end

      # Helper method.  Call this when you want to log an info message.  Logs
      # to the standard logger.
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

      # Make the options hash a HashStruct so that we can access each variable
      # as a method
      def options; @tool_options ||= HashStruct.new(super); end

      # Configure the expected log level and log target.  Handles the
      # --verbose, --very-verbose and --logfile options
      def prepare_logger!
        SC.env[:log_level] = options[:'very-verbose'] ? :debug : (options[:verbose] ? :info : :warn)
        SC.env[:logfile] = File.expand_path(options[:logfile]) if options[:logfile]
      end

      # Configure the current build mode.  Handles the --mode and
      # --environment options.  (--environment is provided for backwards
      # compatibility)
      def prepare_mode!(preferred_mode = 'production')
        build_mode = (options[:mode] || options[:environment] || preferred_mode).to_s.downcase.to_sym
        SC.build_mode = build_mode
      end

      def prepare_app!
        if options[:'build-targets']
          SC.env[:build_targets] = options[:'build-targets'].split(',')
        else
          SC.env[:build_targets] = ''
        end
      end

      def dont_minify!
        SC.env[:dont_minify] = options[:'dont-minify']
      end

      # Configure the current build numbers.  Handles the --build option.
      def prepare_build_numbers!
        return unless (numbers = options[:build])
        numbers = numbers.split(',').map { |n| n.split(':') }
        if numbers.size==1 && numbers.first.size==1
          SC.env.build_number = numbers.first.first
        else
          hash = {}
          numbers.each do |pair|
            key = pair[0]
            key = "/#{key}" if !(key =~ /^\//)
            hash[key.to_sym] = pair[1]
          end
        end
      end

      ################################################
      ## HELPER METHODS
      ##

      # Set the current project.  This is used mostly for unit testing.
      def project=(a_project)
        @project = a_project
      end

      def set_test_project(a_project)
        @project = a_project
        @discovered_project = true
      end

      # The current project.  This is discovered based on the passed --project
      # option or based on the current working directory.  If no project can
      # be found, this method will always return null.
      def project
        return @project if @discovered_project # cache - @project may be nil
        @discovered_project = true

        ret = nil
        project_path = options[:project] || options[:library]

        # if no project_path is named explicitly, attempt to autodiscover from
        # working dir.  If none is found, just set project to nil
        unless project_path
          debug "No project path specified.  Searching for projects in #{Dir.pwd}"
          ret = SC::Project.load_nearest_project Dir.pwd, :parent => SC.builtin_project

        # if project path is specified, look there.  If no project is found
        # die with a fatal exception.
        else
          debug "Project path specified at #{project_path}"
          ret = SC::Project.load File.expand_path(project_path), :parent => SC.builtin_project
          if ret.nil?
            fatal! "Could not load project at #{project_path}"
          end
        end

        # This is the root project, so we must also load the "include targets" used to
        # make additional frameworks available to SC apps.
        SC.include_targets.each {|target|
          target_path = File.expand_path target[:path]
          target_name = File.join "/", target[:name]

          # Note: target names must begin with / to be valid.
          t = ret.add_target target_name, :framework, { :source_root => target_path }

          if t.config[:allow_nested_targets]
            ret.find_targets_for(target_path, target_name, t.config)
          end
        }

        info "Loaded project at: #{ret.project_root}" unless ret.nil?
        @project = ret
      end

      # Attempts to discover the current project.  If no project can be found
      # throws a fatal exception.  Use this method at the top of your tool
      # method if you require a project to run.
      def requires_project!
        ret = project
        if ret.nil?
          fatal!("You do not appear to be inside of a project.  Try changing to your project directory or make sure your project as a Buildfile or sc-config")
        end
        return ret
      end

      # Find one or more targets with the passed target names in the current
      # project.  Requires a project to function.
      def find_targets(*targets)

        debug "finding targets with names: '#{targets * "','"}'"
        requires_project!

        # Filter out any empty target names.  Sometimes this happens when
        # processing arguments.

        targets.reject! { |x| x.nil? || x.size == 0}

        # If targets are specified, find the targets project or parents...
        if targets.size > 0
          targets = targets.map do |target_name|
            begin
              ret = project.target_for(target_name)
            rescue Exception => e
              SC.logger.fatal("Exception when searching for target #{target_name}.  Perhaps your Buildfile is configured wrong?")
              raise e
            end

            if ret.nil?
              fatal! "No target named #{target_name} could be found in PROJECT:#{project.project_root}"
            else
              debug "Found target '#{target_name}' at PROJECT:#{ret.source_root.sub(/^#{project.project_root}\//,'')}"
            end
            ret
          end

        # IF no targets are specified, then just get all targets in project.
        # If --all option was specified, include those that do not autobuild
        else
          targets = project.targets.values
          unless options.all?
            targets.reject! { |t| !t.config.autobuild? }
          end
        end

        appnames = SC.env[:build_targets]

        # if it has the appname argument only build the target with the appname
        if appnames.size > 0
          tar = []
          targets.each do |target|
            appnames.each do |appname|
              if target.target_name.to_s.eql? '/'+appname
                tar << target
              end
            end
          end

          targets = tar
        end

        targets

      end

      # Wraps around find_targets but raises an exception if no target is
      # specified.
      def requires_targets!(*target_names)
        if target_names.size == 0
          fatal! "You must specify a target with this command"
        end

        targets = find_targets(*target_names)
        if targets.size == 0
          fatal! "No targets matching #{target_names * ","} were found."
        end

        targets
      end

      # Requires exactly one target.
      def requires_target!(*targets)
        requires_targets!(*targets).first
      end

      # Discovers the languages requested by the user for a build.  Uses the
      # --languages command line option or disovers in targets.
      def find_languages(*targets)
        # Use passed languages.  If none are specified, merge installed
        # languages for all app targets.
        unless (languages = options.languages)
          languages = targets.map { |t| t.installed_languages }
        else
          languages = languages.split(',').map { |l| l.to_sym }
        end
        languages.flatten.uniq.compact
      end

      # Discovers build numbers requested for the build and sets them in the
      # in the env if needed.
      def find_build_numbers(*targets)
        if options.build_numbers
          numbers = {}
          options.build_numbers.split(',').each do |pair|
            pair = pair.split(':')
            if pair.length < 2
              fatal! "Could not parse build numbers! #{options.build_numbers}"
            end
            numbers["/#{pair[0]}"] = pair[1]
          end
          SC.env.build_numbers = numbers
          SC.logger.info "Using build numbers: #{numbers.map { |k,v| "#{k}: #{v}" }.join(',')}"
        end
      end

      def each_manifest_for_targets(*targets)
        # setup build numbers
        find_build_numbers(*targets)

        requires_project! # get project

        targets = find_targets(*targets) # get targets

        # log output
        SC.logger.info "Building targets: #{targets.map { |t| t.target_name } * ","}"

        languages = find_languages(*targets) # get languages
        SC.logger.info "Building languages: #{ languages * "," }"

        index = 1
        count = targets.length * languages.length
        SC.logger.info "Total target/language combinations to build: #{count}"

        targets.each {|target|
          languages.each {|l|
            manifest = target.manifest_for :language => l
            SC.logger.info "Creating manifest #{index} of #{count} for: #{manifest.target.target_name}:#{manifest.language}"

            yield manifest

            index += 1
          }
        }

      end

      # Core method to process command line options and then build a manifest.
      # Shared by sc-manifest, sc-build and sc-docs commands.
      def build_manifests(*targets)
        # Build'em
        each_manifest_for_targets(*targets) do |manifest|
          manifest.build!

          yield manifest
        end
      end

      # Loops over all of the manifest's entries and builds all essential entries.
      # Entries such as javascript.js are considered non-essential because they will
      # not actually be used in a fully built app (except for modules).
      #
      # It also does a check to ensure that all JS being written is minified.
      def build_entries_for_manifest(manifest, allow_comments)
        if manifest.entries.size > 0
          target = manifest.target
          info "Building entries for #{target.target_name}:#{manifest.language}..."

          # we ONLY generate non-packed javascript.js files for modules, which may need
          # to lazily load them. Otherwise: NOPE!
          generate_javascript = false
          if target[:target_type] === :module
            generate_javascript = true
          end

          target_build_root = Pathname.new(manifest.target.project.project_root)
          manifest.entries.each do |entry|
            # Skip combined JS when it is a target that doesn't need it.
            # We can't just skip all non-packed JS, because you can use sc_resource to split
            # the JS out, and that won't work properly. :combine, likewise, is used for sc_resource.
            # So, we skip the entry IF it is javascript.js--because that is how the pack task itself
            # knows the difference.
            next if not generate_javascript and entry[:filename] == 'javascript.js'

            # For security, skip AND WARN about files which are not minified
            if not SC.env[:dont_minify] and not allow_comments and entry[:entry_type] == :javascript and not entry[:minified]
              SC.logger.fatal "SECURITY: Entry not minified: #{entry[:filename]}; target: #{target[:target_name]}"
              SC.logger.fatal "All entries must be minified in a final build UNLESS --allow-commented-js argument is supplied."
              exit(1)
            end

            dst = Pathname.new(entry.build_path).relative_path_from(target_build_root)
            info "  #{entry.filename} -> #{dst}"
            entry.build!
          end
        end
      end

      # Logs the contents of the passed file path to the logger
      def log_file(path)
        if !File.exists?(path)
          warn "Could not display #{File.basename(path)} at #{File.dirname(path)} because it does not exist."
        end
        file_text = File.read(path)
        SC.logger << file_text
        SC.logger << "\n"
      end

      ################################################
      ## MAIN ENTRYPOINT
      ##

      # Fix start so that it treats command-name like command_name
      def self.start(args = ARGV)
        # manually check for verbose in case we don't get far enough in
        # regular processing to actually set the verbose mode.
        is_verbose = %w(-v -V --verbose --very-verbose).any? { |x| args.include?(x) }
        begin
          super(args)
        rescue Exception => e
          SC.logger.fatal(e)
          if is_verbose && !e.kind_of?(FatalException)
            SC.logger.fatal("BACKTRACE:\n#{e.backtrace.join("\n")}\n")
          end
          exit(1)
        end
      end

    end # no_tasks

  end

end

require "sproutcore/tools/build"
require "sproutcore/tools/build_number"
require "sproutcore/tools/docs"
require "sproutcore/tools/gen"
require "sproutcore/tools/init"
require "sproutcore/tools/manifest"
require "sproutcore/tools/server"

