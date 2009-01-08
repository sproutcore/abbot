module Abbot
  
  # A Manifest describes all of the files that should be found inside of a 
  # single bundle/language.  A Manifest can have global properties assigned to
  # it which will be used by the manifest entries themselves.  This is largly
  # defined by the manifest build tasks.
  #
  class Manifest < HashStruct
    
    attr_reader :bundle
    attr_reader :entries
    
    def initialize(bundle, language)
      super()
      @bundle = bundle 
      @entries = []
      @needs_build = true
      @language = language
    end

    def language; @language; end
    
    # Reset the manifest.  This will clear out the existing manifest and set
    # it to need another build.  The next time you call build!, the manifest
    # will be rebuilt.
    #
    # ==== Returns
    #  self
    #
    def reset!
      @needs_build = true
      @entries = []
      keys.each { |k| self.delete(k) }
      self[:language] = @language
      return self 
    end
    
    # Creates a new manifest entry with the passed options.  Will setup extra
    # tracking needed by entry.
    #
    # ==== Params
    #  opts:: the options you want to set on the entry
    #
    # ==== Returns
    #  the new manifest entry
    #
    def add_entry(opts = {})
      opts[:manifest] = self
      @entries << (ret = ManifestEntry.new(opts))
      return ret 
    end
    
    def needs_build?; @needs_build; end
    
    # Invoke this method to build the manifest for the bundle.  This will
    # execute the manifest:build task from the Buildfile.  If the manifest has
    # already been built, then this method will have no effect.  To rebuild
    # a manifest try:
    #
    #  manifest.reset!.build!
    #
    # === Params
    #  task_name:: the task to invoke to build this manifest.  Usually only needed for unit testing.
    #
    # === Returns
    # self
    #
    def build!(task_name='manifest:build')
      return self unless self.needs_build?
      
      self.reset!
      @needs_build = false
      
      # Execute the manifest:build task.  Be sure to setup the proper env
      bundle.buildfile.execute_task(task_name, 
        :bundle => bundle, :manifest => self, :config => bundle.config)
      
      return self
    end

    # Builds the passed entry.  The entry must belong to the manifest
    def build_entry(entry, build_path)
      bundle.buildfile.execute_task(entry.build_task,
        :bundle => bundle,
        :manifest => self, 
        :entry => entry, 
        :config => bundle.config,
        :dst_path => build_path, 
        :src_path => entry.source_path,
        :src_paths => entry.source_paths)
    end    
    
  end
  
end
