module SC

  # Builds a manifest or a single entry from a manifest
  class Tools::Build < Tools::Tool
    
    def self.build(manifest_or_entry)
      if manifest_or_entry.kind_of?(SC::Manifest)
        manifest_or_entry.entries.each { |e| build(e) }
      else
        e.build!
      end
    end
    
    desc "build [TARGET]", "builds a target"
    method_options :language => :optional, :build  => :optional, 
      :project => :optional, :output => :optional, :verbose => :boolean,
      :languages => :optional
    def build(target_name)
      require 'json'

      apply_build_numbers!
      requires_project!
      requires_target!(target_name)
      
      languages = (options[:languages] || 'en').split(',')
      languages.each do |language|
        manifest = target.manifest_for(language)
        manifest.prepare!.build!.entries.each { |e| e.build! }
      end
      
    end
    
      
  end
  
end

