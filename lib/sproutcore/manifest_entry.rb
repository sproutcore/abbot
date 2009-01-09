require 'ostruct'

module SC

  # A manifest entry describes a single item that can be built by the build
  # system.  A manifest entry can be assigned any properties you like during
  # the manifest build process.
  #
  # A ManifestEntry must have at least the following properties to build:
  #
  #  bundle::       owner bundle
  #  build_rule::   name of the task to invoke to build this entry
  #  build_path::   absolute path to place built files
  #  staging_path:: absolute path to place staging files
  #  source_path::  absolute path to source file  
  #  source_paths:: arrays of source paths to use for build. alt to single
  #  is_hidden:: if true, entry is not included in build
  #
  class ManifestEntry < HashStruct

    def initialize(opts={})
      @manifest = opts.delete :manifest # store manifest has ivar
      super(opts)
    end
    
    # true if the current manifest entry should not be included in the 
    # build.  The entry may still be used as an input for other entries and
    # it may still be referenced directly
    def hidden?; self[:is_hidden] ||= false; end
    
    # Sets the entry's hidden? property to true
    def hide!; self[:is_hidden] = true; self; end

    # true if the manifest entry represents a composite resource built from
    # one or more source entries.  Composite resources will have their 
    # source_entries staged before the entry itself is built to staged.
    def composite?; self[:is_composite]; end
    
    # Marks the entry as composite.  Returns self
    def composite!; self[:is_composite] = true; self; end
    
    # Returns the source_path for the entry.  If the entry is composite, 
    # returns the first entry's staging path.
    def source_path
      composite? ? self.source_paths.first : self[:source_path]
    end

    # Returns all source_paths for the entry.  If the entry is composite,
    # returns the staging paths for the entries.  If the entriy is not
    # composite, uses the source_paths setting or the source_path setting
    def source_paths
      composite? ? self.source_entries.map { |x| x.staging_path } : (self[:source_paths] || [self[:source_path]].compact)
    end

    # Only used if the entry is marked as a composite
    def source_entries; self[:source_entries] || []; end

    # Build path.  Computed from the filename unless otherwise specified
    def build_path
      self[:build_path] || File.join(manifest.build_path, self.filename)
    end
    
    # Staging path.  Computed from the filename unless otherwise specified
    def staging_path
      self[:staging_path] || File.join(manifest.staging_path, self.filename)
    end
    
    # Url.  Computed from filename unless otherwise specified
    def url
      self[:url] || [manifest.url_path, self.filename].join('/')
    end
    
    # The owner manifest
    attr_accessor :manifest

    # The owner bundle
    def bundle; @bundle ||= manifest.bundle; end
    
    ######################################################
    # BUILDING
    #

    # Builds the entry to its target build path.  This method can be invoked
    # an entry to build the file into its file output path.  You must have
    # added this to a manifest first for this to work
    def build!
      self.source_entries.each { |e| e.stage! } if self.composite?
      manifest.build_entry self, self.build_path
      return self
    end

    # Builds an entry into its staging path.  This method can be invoked on 
    # any entry whose output is required by another entry to be built.
    def stage!
      self.source_entries.each { |e| e.stage! } if self.composite?
      manifest.build_entry self, self.staging_path
      return self
    end

  end
  
end
