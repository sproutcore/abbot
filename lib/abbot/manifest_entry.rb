require 'ostruct'

module Abbot
  
  # Defines a single entry in the manifest
  class ManifestEntry < HashStruct

    # true if the current manifest entry should not be included in the 
    # build.  The entry may still be used as an input for other entries and
    # it may still be referenced directly
    def hidden?; self[:is_hidden] ||= false; end
    
    # Sets the entry's hidden? property to true
    def hide!; self[:is_hidden] = true; end

    # The build rule to use when building this manifest.  If none is set
    # explicitly, defaults to the builtin:copy_files build rule.
    def build_rule; self[:build_rule] ||= :'build:copy'; end

    # Returns the bundle this entry belongs to, through its manifest.
    def bundle; manifest.bundle; end
    
    ######################################################
    # BUILDING
    #

    # Builds the entry to its target build path.  This method can be invoked
    # an entry to build the file into its file output path.  You must have
    # added this to a manifest first for this to work
    #
    # ==== Returns
    # receiver
    #
    def build!
      bundle.builder_for(build_rule).build!(self, self.build_path)
      return self
    end

    # Builds an entry into its staging path.  This method can be invoked on 
    # any entry whose output is required by another entry to be built.
    def stage!
      bundle.builder_for(build_rule).build!(self, self.staging_path)
      return self
    end

  end
  
end
