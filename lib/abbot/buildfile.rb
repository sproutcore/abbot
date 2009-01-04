require 'rake'

module Abbot

  # A Buildfile is a special type of Rake Application that knows how to load
  # Abbot build rules.  To load a buildfile, call Buildfile.load() with the 
  # pathname of the build file (or null for an empty file).  You can also
  # pass a parent buildfile which will be used as the basis for the buildfile.
  #
  # Once a buildfile has been instantiated, you can run any task on the
  # buildfile by calling execute_task().  Usually though, you will use a 
  # Buildfile as part of a bundle.  The needed tasks will be invoked as needed
  # to populate the manifest, environment, etc.
  #
  class Buildfile < ::Rake::Application
    
    include ::Rake::Cloneable
    
    # The location of the buildfile represented by this object.
    attr_accessor :path
    
    ################################################
    # CLASS METHODS
    #
    
    # Attempts to locate a buildfile for the specified path.  You can pass
    # in either a path to the file itself or to its parent directory, in
    # which case this method will look for one of Buildfile, sc-config, or 
    # sc-config.rb
    #
    # === Params
    #  path:: The path to search
    #
    # === Returns
    #  The found buildfile path or the same path that was passed in
    #
    def self.buildfile_path_for(path)
      if File.directory?(path)
        %w(Buildfile sc-config sc-config.rb).each do |filename|
          if File.exist?(filename = File.join(path, filename))
            path = filename
            break
          end
        end
      end
      return path
    end
      
    # Loads the buildfile at the specified path.  If you pass a directory
    # instead of a single file, this method will try to find a buildfile 
    # (named Buildfile or sc-config or sc-config.rb).
    #
    # If you pass a directory with no buildfile, this file assumes you meant
    # to load an empty buildfile instance or a copy of the base_buildfile.
    #
    # === Params
    #  path:: the path to laod at
    #  base_buildfile:: a Buildfile instance or nil
    #
    # === Returns
    #  A new Buildfile instance
    #
    def self.load(path, base_buildfile = nil)

      path = buildfile_path_for(path)
          
      # Clone the buildfile object or build a new one
      ret = base_buildfile.nil? ? self.new : base_buildfile.dup
      
      # make the buildfile the current rake application and then load file
      if File.exist?(path)
        ret.path = path
        ret.define { Kernel.load(path); ret.load_imports }
      end
      
      return ret 
    end
    
    # Creates a new Buildfile, optionally using the passed instance as a
    # source, then invokes the passed block with the new receiver as the 
    # current buildfile.  You can use this instead of loading a buildfile.
    #
    # This method is most often used for unit testing.
    #
    # === Params
    #  base_buildfile:: the buildfile to start from
    #
    # === Returns
    #  A new buildfile instance
    #
    def self.define(base_buildfile=nil, &block)
      ret = base_buildfile.nil? ? self.new : base_buildfile.dup
      return ret.define(&block)
    end
      
    ################################################
    # TASK METHODS
    #
    
    # Extend the buildfile dynamically by executing the named task.  This 
    # will yield the block if given after making the buildfile the current
    # build file.
    def define
      
      # reset some common settings
      self.current_mode = :all 
      self.last_description = nil
      
      # save old application and yield
      old_app = Rake.application
      Rake.application = self 
      yield if block_given?
      Rake.application = old_app
      return self
    end
      
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
    
    # Execute rules to build a manifest for the passed manifest.  This will
    # setup the proper global settings and then invoke the manifest:prepare
    # task, if it exists
    def prepare_manifest(manifest)
      execute_task :'manifest:prepare', 
        :manifest => manifest, 
        :bundle => manifest.bundle, 
        :config => manifest.bundle.config
    end
    
    # Execute a build rule for the passed manifest entry.  This will setup the
    # proper global settings and then invoke the build rule, if it exists
    def execute_build_rule(build_rule, entry, build_path)
      execute_task build_rule,
        :entry => entry, 
        :build_path => build_path, 
        :manifest => entry.manifest, 
        :bundle => entry.bundle,
        :config => entry.bundle.config
    end
    
    ################################################
    # CONFIG METHODS
    #
    
    attr_accessor :current_mode
    
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
      mode_name = :all if mode_name.nil?

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
      ret.instance_variable_set('@configs', @configs.deep_clone)
      ret.instance_variable_set('@proxies', @proxies.deep_clone)

      return ret 
    end
    
    protected

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
  
end

# Extend the Rake Task to include ability to clone.  We can't use the builtin
# Cloneable dup method because Task.initialize() expects two parameters.
class Rake::Task
  include ::Rake::Cloneable

  DUP_KEYS = %w(@prerequisites @actions @full_comment @comment @scope @arg_names)
  
  def dup(app=nil)
    app = application if app.nil?
    sibling = self.class.new(name, app)
    DUP_KEYS.each do |key|
      v = self.instance_variable_get(key)
      sibling.instance_variable_set(key, v)
    end
    sibling.taint if tainted?
    sibling
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

# Defines a filter task.  Currently this is just an alias for the task method
alias :filter :task

# Defines a builder task.  Currently this is just an alias for the task 
# method.
alias :builder :task

# Global Helper Methods 

# Buildfile command that will scope any configs inside of the passed block to
# the named build mode.  To scope to all build modes, use mode :all ...
def mode(build_mode, &block)
  old_mode = Rake.application.current_mode
  Rake.application.current_mode = build_mode.to_sym
  yield if block_given?
  Rake.application.current_mode = old_mode
  return self
end

# Buildfile command to register config settings for the named bundle hash. To
# register config settings for all bundles, pass :all
def config(config_name, opts = {}, &block)
  opts = Abbot::HashStruct.new(opts)
  yield(opts) if block_given?
  Rake.application.add_config config_name, opts
  return self
end

# Buildfile command to register a proxy setting.
def proxy(proxy_path, opts={})
  Rake.application.add_proxy proxy_path, opts
end


