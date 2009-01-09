require 'rake'
require File.join(File.dirname(__FILE__), 'hash_struct')

module SC

  # A Buildfile is a special type of Rake Application that knows how to work
  # with SC Buildfiles.  Buildfiles include addition support on top of rake
  # for processing command line arguments, and for automatically building
  # targets.  To load a buildfile, call Buildfile.load() with the 
  # pathname of the build file (or null for an empty file).  You can also
  # pass a parent buildfile which will be used as the basis for the buildfile.
  #
  # Once a buildfile has been instantiated, you can run any task on the
  # buildfile by calling execute_task().  Usually though, you will use a 
  # Buildfile as part of a bundle.  The needed tasks will be invoked as needed
  # to populate the manifest, environment, etc.
  #
  class Buildfile
    
    # Default buildfile names.  Override with SC.env.buildfile_names
    BUILDFILE_NAMES = %w(Buildfile sc-config sc-config.rb)
    
    include ::Rake::Cloneable
    include ::Rake::TaskManager
    
    # The location of the buildfile represented by this object.
    attr_accessor :path
    
    ################################################
    # CLASS METHODS
    #
    
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
    def define!(string=nil, &block)
      context = reset_define_context :current_mode => :all
      instance_eval(string) if string
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
        buildfile_names ||= (SC.env.buildfile_names || BUILDFILE_NAMES)
        buildfile_names.each do |path|
          path = File.join(filename, path)
          next unless File.exist?(path) && !File.directory?(path)
          load!(path)
        end
        
      elsif File.exist?(filename)
        old_path = @current_path
        @current_path = filename
        loaded_paths << filename # save loaded paths
        define!(File.read(filename)) if filename && File.exist?(filename)
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
    def execute_task(task_name, consts = nil)
      consts = set_kernel_consts consts  # save  to restore
      reenable_tasks
      self[task_name.to_s].invoke 
      set_kernel_consts consts # clear constants
    end

    # Reenables all executed tasks.  This will allow tasks to run again even
    # if they have already executed.  This is usually called by execute_task,
    # you will not usually need to call it directly.
    def reenable_tasks
      tasks.each { |task| task.reenable }
      return self
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

    # Application options from the command line
    attr_reader :options

    ################################################
    # CONFIG METHODS
    #
    
    def current_mode
      @define_context.current_mode
    end
    
    def current_mode=(new_mode)
      @define_context.current_mode = new_mode
    end

    # Configures the buildfile for use with the specified target.  Call this
    # BEFORE you load any actual file contents.
    #
    # === Returns
    #  self
    #
    def for_target(target)
      @target_name = target.target_name.to_s
      return self
    end
    
    # The namespace for this buildfile.  This should be name equal to the
    # namespace of the target that owns the buildfile, if there is one
    attr_reader :target_name
    
    # The hash of configs as loaded from the files.  The configs are stored
    # by mode and then by config name.  To get a merged config, use
    # config_for().
    attr_reader :configs
    
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
      config = (mode_configs[config_name.to_sym] ||= HashStruct.new)
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
      ret = HashStruct.new
      
      # now merge em! -- note that this assumes the merge method will handle
      # self.merge(self) & self.merge(nil) gracefully
      ret.merge!(all_configs[:all]) if all_configs
      ret.merge!(cur_configs[:all]) if cur_configs
      ret.merge!(all_configs[config_name]) if all_configs
      ret.merge!(cur_configs[config_name]) if cur_configs
      
      # Done -- return result
      return ret  
    end      

    ################################################
    # PROJECT & TARGET METHODS
    #

    def project_type; @project_type || :default; end
    attr_writer :project_type
    
    ################################################
    # PROXY METHODS
    #
    
    # The hash of all proxies paths and their options
    attr_reader :proxies
    
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
      @proxies[proxy_path] = HashStruct.new(opts)
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
      tasks = ret.instance_variable_get('@tasks')
      tasks.each do | key, task |
        tasks[key] = task.dup(ret)
      end
      
      # Deep clone the config and proxy hashes as well...
      %w(@configs @proxies @options).each do |ivar|
        cloned_ivar = instance_variable_get(ivar).deep_clone
        ret.instance_variable_set(ivar, cloned_ivar)
      end
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
    
    # For each key in the passed hash, this will register a global 
    def set_kernel_consts(env = nil)
      return env if env.nil?

      # for each item in the passed environment, convert to uppercase constant
      # and set in global namespace.  Save the old value so that it can be
      # restored later.
      ret = {}
      env.each do |key, value|
        const_key = key.to_s.upcase.to_sym
        
        # Save the old const value
        ret[key] = Kernel.const_get(const_key) rescue nil
        
        # If the old value differs from the new value, change it
        Kernel.const_reset(const_key, value) if ret[key] != value
      end
      
      return ret
    end
      
  end
  
  # The task will only be executed if the destination path does not exist or
  # if it's timestamp is older than any of the source paths.
  class BuildTask < ::Rake::Task
    
    def needed?
      return true if out_of_date?
    end
    
    def out_of_date?
      ret = false
      dst_mtime = File.exist?(DST_PATH) ? File.mtime(DST_PATH) : Rake::EARLY
      SRC_PATHS.each do |path|
        timestamp = File.exist?(path) ? File.mtime(path) : Rake::EARLY
        ret = ret || (dst_mtime < timestamp)
        break if ret
      end
      return ret 
    end
    
  end
  
end

# Add public method to kernel to remove defined constant using private
# method.
module Kernel
  def const_reset(key, value)
    remove_const(key) if const_defined?(key)
    const_set key, value
  end
end

# Global Helper Methods 

def build_task(*args, &block)
  SC::BuildTask.define_task(*args, &block)
end

# Generic CACHES constant can be used by tasks.
CACHES = SC::HashStruct.new

SC.require_all_libs_relative_to(__FILE__)

