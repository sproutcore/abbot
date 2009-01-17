module SC
  
  # A Manifest describes all of the files that should be found inside of a 
  # single bundle/language.  A Manifest can have global properties assigned to
  # it which will be used by the manifest entries themselves.  This is largly
  # defined by the manifest build tasks.
  #
  class Manifest < HashStruct
    
    attr_reader :target
    
    def entries(opts={})
      include_hidden = opts[:hidden] || false
      return @entries if include_hidden
      @entries.reject { |e| e.hidden? }
    end
    
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
        target.prepare!
        if target.buildfile.task_defined? 'manifest:prepare'
          target.buildfile.invoke 'manifest:prepare',
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
        target.buildfile.invoke 'manifest:build',
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
    def to_hash(opts={})
      ret = super()
      
      if only_keys = opts[:only]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value if only_keys.include?(key)
        end
        ret = filtered
      end

      # Always include entries unless they are explicitly excluded
      ret[:entries] = entries(opts).map { |e| e.to_hash(opts) }
      
      if except_keys = opts[:except]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value unless except_keys.include?(key)
        end
        ret = filtered
      end

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
    def load(hash)
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
    
    # Creates a composite entry with the passed filename.  Expects you to
    # a source_entries option.  This automatically hides the source entries
    # unless you pass the :hide_entries => false option.
    def add_composite(filename, opts = {})
      should_hide_entries = opts.delete(:hide_entries)
      should_hide_entries = true if should_hide_entries.nil?
      
      opts[:filename] = filename
      opts[:source_entries] ||= []
      opts[:composite] = true
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!
      
      ret.source_entries.each { |entry| entry.hide! } if should_hide_entries
      return ret 
    end
    
    # Creates an entry with will apply a build task to the source entry. Use
    # this method when you need to apply a build task to an entry to convert
    # it into another format or to perform some kind of incremental build.
    #
    # === Params
    #  entry:: the entry that should be the source of the transform
    #
    # === Options
    # You can assign any options you like and they will be copied onto the
    # new entry.  The following options, however, have special meaning:
    #
    #  :build_task:: name the new build task you use.  otherwise uses copy
    #  :ext:: the new file extension. if you don't override, the build_path
    #    staging_path and filename will all be adjusted to have this ext.
    #
    # === Returns 
    #   the new ManifestEntry
    # 
    def add_transform(entry, opts ={})

      # Clone important properties to new transform...
      opts = HashStruct.new(opts)
      %w(filename build_path url).each do |key|
        opts[key] ||= entry[key]
      end
      
      # generate a unique staging path...
      opts.staging_path ||= unique_staging_path(entry.staging_path)
      opts.source_entry   = entry
      opts.source_entries = [entry]
      opts.composite      = true
      opts.transform      = true # make .transform? = true
      
      # Normalize to new extension if provided.  else copy ext from entry...
      if opts.ext
        %w(filename build_path staging_path url).each do |key|
          opts[key] = opts[key].ext(opts.ext)
        end
        opts.ext = opts.ext.to_s
      else
        opts.ext = entry.ext
      end

      # Create new entry and hide old one
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!
      entry.hide!
      
      # done!
      return ret 
    end
    
    # Finds the first visible entry with the specified filename.  Include
    # hidden if you like.
    #
    # === Params
    #   filename:: the filename to search
    # 
    # === Options
    #   :hidden:: if true, include hidden entries
    #
    # === Returns
    #   the manifest entry
    def entry_for(filename, opts = {})
      entries(:hidden => opts[:hidden]).find do |entry| 
        (entry.filename == filename) && entry.has_options?(opts)
      end
    end
    
    # Finds a unique staging path starting with the root proposed staging
    # path.
    def unique_staging_path(path)
      paths = entries(:hidden => true).map { |e| e.staging_path }
      while paths.include?(path)
        path = path.sub(/(__\$[0-9]+)?(\.\w+)?$/,"__$#{next_staging_uuid}\\2")
      end
      return path
    end
    
    protected
    
    def next_staging_uuid
      self.staging_uuid = (self.staging_uuid || 0) + 1
    end
    
  end
  
end
