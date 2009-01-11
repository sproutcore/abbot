module SC
  
  # A Manifest describes all of the files that should be found inside of a 
  # single bundle/language.  A Manifest can have global properties assigned to
  # it which will be used by the manifest entries themselves.  This is largly
  # defined by the manifest build tasks.
  #
  class Manifest < HashStruct
    
    attr_reader :target
    attr_reader :entries
    
    def initialize(target, opts)
      super(opts)
      @target = target 
      @entries = []
    end

    # Invoked just before a manifest is built.  If you load a manifest file
    # this method will not be invoked.
    # === Returns
    #  self
    def prepare!
      if !@is_prepared
        @is_prepared = true
        if target.buildfile.task_defined? 'manifest:prepare'
          target.buildfile.execute_task 'manifest:prepare',
            :manifest => self, 
            :target => self.target, 
            :config => self.target.config,
            :project => self.target.project
        end
      end 
      return self
    end

    def prepared?; @is_prepared || false; end
    
    # Builds the manifest.  This will prepare the manifest and then invoke
    # the manifest:build task if defined.
    def build!
      prepare!
      reset_entries!
      if target.buildfile.task_defined? 'manifest:build'
        target.buildfile.execute_task 'manifest:build',
          :manifest => self,
          :target => self.target,
          :config => self.target.config,
          :project => self.target.project
      end
      return self
    end
    
    # Resets the manifest entries.  this is called before a build is 
    # performed. This will reset only the entries, none of the other props.
    #
    # === Returns
    #   Manifest (self)
    #
    def reset_entries!
      @entries = []
      return self
    end
      
    # Returns the manifest as a hash that can be serialized to json or yaml
    def to_hash
      ret = super
      ret[:entries] = entries.map { |e| e.to_hash }
      return ret
    end
    
    # Loads a hash into the manifest, replacing whatever contents are
    # already here.
    #
    # === Params
    #  hash:: the hash loaded from disk
    #
    # === Returns
    #  Manifest (self)
    #
    def load_hash!(hash)
      merge!(hash)
      entry_hashes = self.delete(:entries) || []
      @entries = entry_hashes.map do |opts|
        ManifestEntry.new(self, opts)
      end
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
    def add_entry(filename, opts = {})
      opts[:filename] = filename
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!
      return ret 
    end
    
  end
  
end
