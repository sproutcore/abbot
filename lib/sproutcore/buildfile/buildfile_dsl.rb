# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  class Buildfile

    # This class allows us to memoize common computations
    class Config < HashStruct
      def target_names
        @target_names ||= self[:target_types].keys
      end
    end

    # Describe the domain-specific-language helpers supported by buildfiles.
    # This is included as a mixin for the buildfile.
    module Commands

      # Declare a basic task.
      #
      # Example:
      #   task :clobber => [:clean] do
      #     rm_rf "html"
      #   end
      #
      def task(*args, &block)
        define_task(::SC::Buildfile::Task, *args, &block)
      end

      # Replace an existing task instead of enhancing it.
      #
      # Example:
      #   replace_task :clobber => :clean do
      #      rm_rf 'javascript'
      #   end
      #
      def replace_task(*args, &block)
        @is_redefining = true
        begin
          define_task(::SC::Buildfile::Task, *args, &block)
        rescue Exception => e
          @is_redefining = false
          raise e
        end
      end

      # Define a build task.  A build task will not run if the destination
      # file is newer than the source files.
      #
      def build_task(*args, &block)
        define_task(::SC::Buildfile::BuildTask, *args, &block)
      end

      # Import the partial Rakefiles +fn+.  Imported files are loaded _after_
      # the current file is completely loaded.  This allows the import statement
      # to appear anywhere in the importing file, and yet allowing the imported
      # files to depend on objects defined in the importing file.
      #
      # A common use of the import statement is to include files containing
      # dependency declarations.
      #
      # Example:
      #   import ".depend", "my_rules"
      #
      def import(*args)
        base_path = current_path.nil? ? nil : File.dirname(current_path)
        args.each do |fn|
          fn = File.expand_path(fn, base_path)
          add_import(fn)
        end
      end

      # Create a new rake namespace and use it for evaluating the given block.
      # Returns a NameSpace object that can be used to lookup tasks defined in
      # the namespace.
      #
      # E.g.
      #
      #   ns = namespace "nested" do
      #     task :run
      #   end
      #   task_run = ns[:run] # find :run in the given namespace.
      #
      def namespace(name=nil, &block)
        in_namespace(name, &block)
      end

      # Describe the next rake task.
      #
      # Example:
      #   desc "Run the Unit Tests"
      #   task :test => [:build]
      #     runtests
      #   end
      #
      def desc(description)
        last_description = description
      end

      # Describe options on the next rake task.
      #
      # Example:
      #   options :log => :env|:name|:none
      #   task :test => [:build]
      #     runtests
      #   end
      #
      def task_options(opts)
        last_task_options = opts
      end

      # Scope any config statements inside the passed block to the named mode.
      # Normally if you call a config statement outside of a mode block, it will
      # scope to all modes.
      #
      # Example:
      # mode :debug do
      #  config :all, :combine_javascript => NO
      #
      def mode(build_mode, &block)
        old_mode = current_mode
        self.current_mode = build_mode.to_sym
        yield if block_given?
        self.current_mode = old_mode
        return self
      end

      # Register the passed configuration settings scoped to a target.  Optional
      # pass a block to edit the config.
      #
      # Example:
      #  config :all, :url_root => "static"
      #  config :sproutcore do |c|
      #     c.url_root = "static"
      #  end
      #
      def config(config_name, opts = {}, &block)
        opts = ::SC::Buildfile::Config.new(opts)
        yield(opts) if block_given?
        add_config config_name, opts
        return self
      end

      # Register a proxy setting
      #
      # Example:
      #  proxy '/url', :to => 'localhost:3000'
      #
      def proxy(proxy_path, opts={})
        add_proxy proxy_path, opts
      end

      # Register info about this buildfile as a project
      def project(name=nil, type=nil)
        self.project_name = name.nil? ? :default : name.to_sym
        self.project_type = type.nil? ? :default : type.to_sym
        self.project!
      end

    end

    include Commands
  end

end
