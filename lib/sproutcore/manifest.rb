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
      @is_prepared = NO
    end

    def prepared?; @is_prepared; end
    def prepared!; @is_prepared = YES; end

    def to_hash
      ret = super
      ret[:entries] = entries.map { |e| e.to_hash }
      return ret
    end
    
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
    
  end
  
end
