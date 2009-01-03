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
    # === Params
    #  path:: the path to laod at
    #  base_buildfile:: a Buildfile instance or nil
    #
    # === Returns
    #  A new Buildfile instance
    #
    def self.load(path, base_buildfile = nil)

      path = buildfile_path_for(path)
      raise "No Buildfile found at #{path}" unless File.exist?(path)
          
      # Clone the buildfile object or build a new one
      ret = base_buildfile.nil? ? self.new : base_buildfile.dup
      ret.path = path
      
      # make the buildfile the current rake application and then load file
      return ret.define { Kernel.load(path); ret.load_imports }
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
    # INTERNAL SUPPORT
    #
    
    # When dup'ing, rewrite the @tasks hash to use clones of the tasks 
    # the point to the new application object.
    def dup
      ret = super
      tasks = ret.instance_variable_get('@tasks')
      tasks.each do | key, task |
        tasks[key] = task.dup(ret)
      end
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
