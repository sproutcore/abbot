# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/models/hash_struct"
require "sproutcore/buildfile/cloneable"
require "sproutcore/buildfile/task_manager"

module SC

  # A Buildfile is a special type of file that contains the configurations and
  # build tasks used for a particular project or project target.  Buildfiles
  # are based on Rake but largely use their own syntax and helper methods.
  #
  # Whenever you create a project, you will often also add a Buildfile,
  # sc-config, or sc-config.rb file.  All of these files are laoded into the
  # build system using this class.  The other model objects will then
  # reference their buildfile to extract configuration information and to find
  # key tasks required for the build process.
  #
  # == Loading a Buildfile
  #
  # To load a buildfile, just use the load() method:
  #
  #   buildfile = Buildfile.load('/path/to/buildfile')
  #
  # You can also load multiple buildfiles by calling the load!() method on
  # an exising Buildfile object or by passing a directory with several
  # buildfiles in it:
  #
  #   buildfile = Buildfile.new
  #   buildfile.load!('buildfile1').load!('buildfile2')
  #
  # == Defining a Buildfile
  #
  # Finally, you can also define new settings on a buildfile directly.  Simply
  # use the define() method:
  #
  #   buildfile = Buildfile.define do
  #     task :demo_task
  #   end
  #
  # You can also define additional tasks on an existing buildfile object like
  # so:
  #
  #  buildfile = Buildfile.new
  #  buildfile.define! do
  #    task :demo_task
  #  end
  #
  # When you call define!() on a buildfile, the block is executed in the
  # context of the buildfile object, just like a Buildfile loaded from disk.
  # You will not usually use define!() on a buildfile in normal code, but it
  # is very useful for unit testing.
  #
  # == Executing Tasks
  #
  # Once a buildfile is loaded, you can execute tasks on the buildfile using
  # the invoke() method.  You should pass the name of the task you want
  # to execute along with any constants you want set for the task to access:
  #
  #   buildfile.invoke :demo_task, :context => my_context
  #
  # With the above example, the demo_task could access the "context" as a
  # global constant like do:
  #
  #   task :demo_task do
  #      CONTEXT.name = "demo!"
  #   end
  #
  # == Accessing Configs
  #
  # Configs are stored in a "normalized" state in the "configs" property.  You
  # can access configs directly this way, but the more useful way to access
  # configs is through the config_for() method.  Pass the name of the target
  # that is the current "focus" of the config:
  #
  #   config = buildfile.config_for('/sproutcore') # target always starts w /
  #
  # Configs can be specified in different "contexts" by the buildfile.  When
  # you call this method, the configs will be merged together, layering any
  # configs that are targeted specifically at the /sproutcore target over the
  # top of globally defined configs.  The current build mode is also reflected
  # in this call.
  #
  class Buildfile

    # Default buildfile names.  Override with SC.env.buildfile_names
    BUILDFILE_NAMES = %w(Buildfile sc-config sc-config.rb)

    include TaskManager

    # The location of the buildfile represented by this object.
    attr_accessor :path

    ################################################
    # CLASS METHODS
    #

    # Determines if this directory has a buildfile or not...
    def self.has_buildfile?(dir_path, buildfile_names=nil)
      buildfile_names ||= (SC.env[:buildfile_names] || BUILDFILE_NAMES)
      buildfile_names.each do |path|
        path = File.join(dir_path, path)
        return true if File.exist?(path) && !File.directory?(path)
      end
      return false
    end

    # Loads the buildfile at the specified path.  This simply creates a new
    # instance and loads it.
    #
    # === Params
    #  path:: the path to laod at
    #
    # === Returns
    #  A new Buildfile instance
    #
    def self.load(path)
      self.new.load!(path)
    end

    # Creates a new buildfile and then gives you an opportunity to define
    # its contents by executing the passed block in the context of the
    # buildfile.
    #
    # === Returns
    #  A new buildfile instance
    #
    def self.define(&block)
      self.new.define!(&block)
    end

    ################################################
    # TASK METHODS
    #

    attr_reader :current_path

    # Extend the buildfile dynamically by executing the named task.  This
    # will yield the block if given after making the buildfile the current
    # build file.
    #
    # === Params
    #   string:: optional string to eval
    #   &block:: optional block to execute
    #
    # === Returns
    #   self
    #
    def define!(string=nil, filename="(unknown Buildfile)", &block)
      context = reset_define_context :current_mode => :all
      instance_eval(string, filename) if string
      instance_eval(&block) if block_given?
      load_imports
      reset_define_context context
      return self
    end

    def task_defined?(task_name)
      !!lookup(task_name)
    end

    # Loads the contents of the passed file into the buildfile object.  The
    # contents will be executed in the context of the buildfile object.  If
    # the filename passed is nil or the file does not exist, this will simply
    # do nothing.
    #
    # === Params
    #  filename:: the buildfile to load or a directory
    #  buildfile_names:: optional array of names to search in directory
    #
    # === Returns
    #  self

    def load!(filename=nil, buildfile_names=nil)

      # If a directory is passed, look for any buildfile and load them...
      if File.directory?(filename)

        # search directory for buildfiles and load them.
        buildfile_names ||= (SC.env[:buildfile_names] || BUILDFILE_NAMES)
        buildfile_names.each do |path|
          path = File.join(filename, path)
          next unless File.exist?(path) && !File.directory?(path)
          load!(path)
        end

      elsif File.exist?(filename)
        old_path = @current_path
        @current_path = filename
        loaded_paths << filename # save loaded paths
        SC.logger.debug "Loading buildfile at #{filename}"
        define!(File.read(filename), filename) if filename && File.exist?(filename)
        @current_path = old_path
      end
      return self
    end

    def loaded_paths; @loaded_paths ||= []; end

    # Executes the name task.  Unlike invoke_task, this method will execute
    # the task even if it has already been executed before.  You can also
    # pass a hash of additional constants that will be set on the global
    # namespace before the task is invoked.
    #
    # === Params
    #  task_name:: the full name of the task, including namespaces
    #  consts:: Optional hash of constant values to set on the env
    def invoke(task_name, consts = {})
      original, SproutCore::RakeConstants.constant_list = SproutCore::RakeConstants.constant_list, consts
      self[task_name].invoke(consts)
    ensure
      SproutCore::RakeConstants.constant_list = original
    end

    # Returns true if the buildfile has the named task defined
    #
    # === Params
    #  task_name:: the full name of the task, including namespaces
    def has_task?(task_name)
      !self[task_name.to_s].nil?
    end

    ################################################
    # RAKE SUPPORT
    #

    # Add a file to the list of files to be imported.
    def add_import(fn)
      @pending_imports << fn
    end

    # Load the pending list of imported files.
    def load_imports
      while fn = @pending_imports.shift
        next if @imported.member?(fn)
        if fn_task = lookup(fn)
          fn_task.invoke
        end
        load!(fn)
        @imported << fn
      end
    end

    # Support redefining a task...
    def intern(task_class, task_name)
      ret = super(task_class, task_name)
      ret.clear if @is_redefining
      return ret
    end

    # Application options from the command line
    attr_accessor :options

    ################################################
    # CONFIG METHODS
    #

    def current_mode
      @define_context[:current_mode]
    end

    def current_mode=(new_mode)
      @define_context[:current_mode] = new_mode
    end

    # Configures the buildfile for use with the specified target.  Call this
    # BEFORE you load any actual file contents.
    #
    # === Returns
    #  self
    #
    def for_target(target)
      @target_name = target[:target_name].to_s
      return self
    end

    # The namespace for this buildfile.  This should be name equal to the
    # namespace of the target that owns the buildfile, if there is one
    attr_reader :target_name

    # The hash of configs as loaded from the files.  The configs are stored
    # by mode and then by config name.  To get a merged config, use
    # config_for().
    attr_accessor :configs

    # The hash of proxy commands

    # Merge the passed hash of options into the config hash.  This method
    # is usually used by the config global helper
    #
    # === Params
    #  config_name:: the name of the config to set
    #  config_mode:: the mode to store the config.  If omitted use current
    #  opts:  the config options to merge in
    #
    # === Returns
    #  receiver
    #
    def add_config(config_name, config_mode, opts=nil)
      # Normalize Params
      if opts.nil?
        opts = config_mode; config_mode = nil
      end
      config_mode = current_mode if config_mode.nil?

      # Normalize the config name -- :all or 'all' is OK, absolute OK.
      config_name = config_name.to_s
      if config_name != 'all' && (config_name[0..0] != '/')
        if target_name && (config_name == File.basename(target_name))
          config_name = target_name
        else
          config_name = [target_name, config_name].join('/')
        end
      end

      # Perform Merge
      mode_configs = (self.configs[config_mode.to_sym] ||= HashStruct.new)
      config = (mode_configs[config_name.to_sym] ||= ::SC::Buildfile::Config.new)
      config.merge!(opts)
    end

    # Returns the merged config setting for the config name and mode.  If
    # no mode is specified the :all mode is assumed.
    #
    # This will merge config hashes in the following order (mode/name):
    #
    # all:all -> mode:all -> all:config -> mode:config
    #
    #

    # === Params
    #  config_name:: The config name
    #  mode_name:: optional mode name
    #
    # === Returns
    #  merged config -- a HashStruct
    def config_for(config_name, mode_name=nil)
      mode_name = :all if mode_name.nil? || mode_name.to_s.size == 0
      config_name = :all if config_name.nil? || config_name.to_s.size == 0

      # collect the hashes
      all_configs = configs[:all]
      cur_configs = configs[mode_name]
      ret = ::SC::Buildfile::Config.new

      # now merge em! -- note that this assumes the merge method will handle
      # self.merge(self) & self.merge(nil) gracefully
      ret.merge!(all_configs[:all]) if all_configs
      ret.merge!(cur_configs[:all]) if cur_configs
      ret.merge!(all_configs[config_name.to_sym]) if all_configs
      ret.merge!(cur_configs[config_name.to_sym]) if cur_configs

      # Done -- return result
      return ret
    end

    ################################################
    # PROJECT & TARGET METHODS
    #

    # This is set if you use the project helper method in your buildfile.
    attr_accessor :project_name

    def project_type; @project_type || :default; end
    attr_writer :project_type

    attr_writer :is_project
    protected :is_project=

    # Returns YES if this buildfile appears to represent a project.  If you
    # use the project() helper method, it will set this
    def project?; @is_project || false; end
    def project!; @is_project = true; end

    ################################################
    # PROXY METHODS
    #

    # The hash of all proxies paths and their options
    attr_accessor :proxies

    # Adds a proxy to the list of proxy paths.  These are used only in server
    # mode to proxy certain URLs.  If you call this method with the same
    # proxy path more than once, the options will be merged.
    #
    # === Params
    #  :proxy_path the URL to proxy
    #  :opts any proxy options
    #
    # === Returns
    #  receiver
    #
    def add_proxy(proxy_path, opts={})
      @proxies[proxy_path.to_sym] = HashStruct.new(opts)
      return self
    end

    ################################################
    # INTERNAL SUPPORT
    #

    def initialize
      super
      @configs = HashStruct.new
      @proxies = HashStruct.new
      @pending_imports = []
      @imported = []
      @options = HashStruct.new
    end

    # When dup'ing, rewrite the @tasks hash to use clones of the tasks
    # the point to the new application object.
    def dup
      ret = super

      # Make sure the tasks themselves are cloned
      ret_tasks = ret.instance_variable_set("@tasks", {})
      @tasks.each do | key, task |
        ret_tasks[key] = task.dup(ret)
      end

      # Deep clone the config and proxy hashes as well...
      ret.configs = Marshal.load(Marshal.dump(configs))
      ret.proxies = Marshal.load(Marshal.dump(proxies))
      ret.options = Marshal.load(Marshal.dump(options))

      ret.is_project = false if ret.project?

      return ret
    end

    protected

    # Save off the old define context and replace it with the passed context
    # This is used during a call to define()
    def reset_define_context(context=nil)
      ret = @define_context
      @define_context = HashStruct.new(context || {})
      return ret
    end

  end

end

module SproutCore
 module RakeConstants
   class << self
     attr_accessor :constant_list
   end

   def const_missing(name)
     ret = (RakeConstants.constant_list && RakeConstants.constant_list[name.to_s.downcase.to_sym]) || super
   end
 end
end

# Add public method to kernel to remove defined constant using private
# method.
class Object
  extend SproutCore::RakeConstants

  def self.const_reset(key, value)
    remove_const(key) if const_defined?(key)
    const_set key, value
  end
end

# back-compat
module Kernel
  def self.const_reset(key, value)
    SC.logger.warn "const_reset is deprecated. Called from #{caller[0]}"
    Object.const_reset(key, value)
  end
end

require "sproutcore/buildfile/build_task"
require "sproutcore/buildfile/buildfile_dsl"
require "sproutcore/buildfile/early_time"
require "sproutcore/buildfile/invocation_chain"
require "sproutcore/buildfile/namespace"
require "sproutcore/buildfile/string_ext"
require "sproutcore/buildfile/task"
require "sproutcore/buildfile/task_arguments"
require "sproutcore/buildfile/task_manager"

