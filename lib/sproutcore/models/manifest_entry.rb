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

    def initialize(manifest, opts={})
      @manifest = manifest # store manifest has ivar
      super(opts)
    end
    
    # invoked whenever the manifest entry is first created.  This will invoke
    # the entry:prepare task if defined.
    def prepare!
      if !@is_prepared
        @is_prepared = true
        buildfile = manifest.target.buildfile
        if buildfile.task_defined? 'entry:prepare'
          buildfile.invoke 'entry:prepare',
            :entry => self,
            :manifest => self.manifest,
            :target => self.manifest.target,
            :config => self.manifest.target.config,
            :project => self.manifest.target.project
        end
      end
      return self
    end
    
    def prepared?; @is_prepared || false; end
    
    ######################################################
    # CONVENIENCE METHODS
    #
    
    # true if the current manifest entry should not be included in the 
    # build.  The entry may still be used as an input for other entries and
    # it may still be referenced directly
    def hidden?; self[:hidden] ||= false; end
    
    # Sets the entry's hidden? property to true
    def hide!; self[:hidden] = true; self; end

    # true if the manifest entry represents a composite resource built from
    # one or more source entries.  Composite resources will have their 
    # source_entries staged before the entry itself is built to staged.
    def composite?; self[:composite]; end
    
    # Marks the entry as composite.  Returns self
    def composite!; self[:composite] = true; self; end
    
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

    # The owner manifest
    attr_accessor :manifest

    # The owner target
    def target; @target ||= manifest.target; end
    
    ######################################################
    # BUILDING
    #

    # Invokes the entry's build task to build to its build path.  If the 
    # entry has source entries, they will be staged first.
    def build!
      build_to self.build_path
    end

    # Builds an entry into its staging path.  This method can be invoked on 
    # any entry whose output is required by another entry to be built.
    def stage!
      build_to self.staging_path
    end
    
    private 
    
    def build_to(dst_path)
      if self.build_task.nil?
        raise "no build task defined for #{self.filename}" 
      end

      # stage source entries if needed...
      (self.source_entries || []).each { |e| e.stage! } if composite?
      
      # get build task and build it
      buildfile = manifest.target.buildfile
      if !buildfile.task_defined?(self.build_task)
        raise "Could not build entry #{self.filename} because build task '#{self.build_task}' is not defined"
      end
      
      buildfile.invoke self.build_task,
        :entry => self,
        :manifest => self.manifest,
        :target => self.manifest.target,
        :config => self.manifest.target.config,
        :project => self.manifest.target.project,
        :src_path => self.source_path,
        :src_paths => self.source_paths,
        :dst_path => dst_path
        
      return self
    end  

  end
  
end
