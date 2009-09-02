# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

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
    
    def inspect 
      "SC::ManifestEntry(#{filename}, build_task=>#{self.build_task}, entry_type=>#{self.entry_type}, is_hidden=>#{self.hidden?})"
    end
    
    def to_hash(opts={})
      ret = super()
      if ret[:source_entries]
        ret[:source_entries] = ret[:source_entries].map { |e| e.to_hash(opts)}
      end
      
      if only_keys = opts[:only]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value if only_keys.include?(key)
        end
        ret = filtered
      end
      
      if except_keys = opts[:except]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value unless except_keys.include?(key)
        end
        ret = filtered
      end

      return ret
    end
    
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
    
    # The owner manifest
    attr_accessor :manifest
    
    def dynamic?; self[:dynamic]; end
    
    # The owner target
    def target; @target ||= manifest.target; end
    
    # dynamic_required targets, only applicable to bundle_info entries
    def targets; self[:targets]; end
    
    # variation for dynamic_required targets, only applicable to bundle_info
    # entries
    def variation; self[:variation]; end
    
    # Returns a timestamp for when this file was last changed.  This will
    # reach back to the source entries, finding the latest original entry.
    def timestamp
      if dynamic? # MUST check for this first...
        timestamps = targets.map do |t|
          timestamps2 = t.manifest_for(variation).build!.entries.map do |e|
            ts = e.timestamp
            ts.nil? ? 0 : ts
          end
          timestamps2.max
        end
        timestamps.max
      elsif composite?
        source_entries.map { |e| e.timestamp }.max
      else
        File.exist?(source_path) ? File.mtime(source_path).to_i : 0
      end
    end
    
    # Returns a URL with a possible timestamp token appended to the end of 
    # the entry if the target's timestamp_url config is set.  Otherwise
    # returns the URL itself.
    def cacheable_url
      ret = self.url
      ret = [ret, self.timestamp].join('?') if target.config.timestamp_urls
      return ret
    end
    
    # Scans the source paths (first staging any source entries) for the 
    # passed regex.  Your block will be executed with each line that matched.
    # Returns the results of each block
    #
    # === Example
    #
    #  entry.extract_content(/require\((.+)\)/) { |line| $1 }
    #
    def scan_source(regexp, &block)
      if entries = self.source_entries
        entries.each { |entry| entry.stage! }
      end

      if paths = self.source_paths
        paths.each do |path|
          next unless File.exist?(path)
          File.readlines(path).each do |line|
            if (line.valid_encoding?)
              line.scan(regexp) { |result| yield(result) }
            end
          end 
        end
      end
    end

    BUILD_DIRECTIVES_REGEX = /(sc_require|require|sc_resource)\(\s*(['"])(.+)['"]\s*\)/
    
    # Scans the source paths for standard build directives and annotates the
    # entry accordingly.  You should only call this method on entries 
    # representing CSS or JavaScript resources.  It will yield undefined
    # results on all other file types.
    #
    def discover_build_directives!
      self.required = []
      entry = self.transform? ? self.source_entry : self
      entry.scan_source(BUILD_DIRECTIVES_REGEX) do |matches|
        # strip off any file ext
        filename = matches[2].ext ''
        case matches[0]
        when 'sc_require'
          self.required << filename
        when 'require'
          self.required << filename
        when 'sc_resource'
          self.resource = filename
        end
      end
    end
    
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
    
    # Removes the build and staging files for this entry so the next 
    # build will rebuild.
    #
    # === Returns
    #  self
    def clean!
      FileUtils.rm(self.build_path) if File.exist?(self.build_path)
      FileUtils.rm(self.staging_path) if File.exist?(self.staging_path)
      return self 
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
