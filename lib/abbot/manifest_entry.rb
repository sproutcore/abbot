module Abbot
  
  # Defines a single entry in the manifest
  class ManifestEntry < Hash
    
    # Owner manifest
    attr_reader :manifest 
    
    attr_reader :source_path
    attr_reader :source_entries

    attr_reader :build_path
    attr_reader :staging_path
    attr_reader :url
    
    def hidden?; @is_hidden || false; end
    def hide!; @is_hidden = true; end
    
    def initialize(opts = {})
      self.manifest = opts[:manifest]
      self.source_path = opts[:source_path]
      self.source_entries = opts[:source_entries] || []
      
      self.build_rule = :'abbot:build:copy'
    end
        
    # This will actually build the entry, copying it to the target build 
    # path
    def build!
      self.manifest.bundle.builder_for(self.build_rule).build!(self, self.build_path)
      return self
    end

    # This will build the entry, copying it to the staging path
    def stage!
      self.manifest.bundle.builder_for(self.build_rule).build!(self, self.staging_path)
      return self
    end
    
  end
  
end
