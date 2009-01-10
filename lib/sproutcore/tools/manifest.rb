module SC
    
  # Prepares a manifest for use in the build system.  A manifest maps every
  # resources in a source directory to the output resources in a target 
  # directory along with any metadata and other options needed to actually
  # build the resources.
  #
  # Typically a manifest is generated automatically when you perform an 
  # sc-build or when you use sc-server.  However, you may choose to 
  # explicitly generate a manifest either for diagnostic purposes or to 
  # perform some postprocessing on the manifest before it is used in the
  # build.
  #
  # Optionally you can also override some methods in this tool to change
  # the way a manifest is generated.
  #
  # == Extending the Manifest Tool
  #
  # The main entrypoint for this tool is the prepare() method.  This method
  # simply calls out to several other methods to perform transforms on the
  # manifest.  By overriding this method, you can insert your own extra 
  # transforms or make whatever other change you want.  You can also 
  # override the specific transform methods if you need to change their
  # behavior instead.
  #
  class Tools::Manifest < Tools::Tool
        
    # Entry point for internal use.  This will create an instance, save
    # the current project, target, and manifest and then call prepare!
    #
    # === Params
    #  manifest:: the manifest to prepare
    #  
    # === Returns
    #  the prepared manifest, which should replace the one you pass in.
    #
    def self.build(manifest)
      tool = self.new
      tool.manifest = manifest 
      tool.target = manifest.target
      tool.project = manifest.project
      tool.build!
      return manifest
    end
    
    # Entry point for a command line tool.
    desc "build TARGET", "generates a manifest file for the target"
    method_options :language => :optional, :build  => :optional, 
      :project => :optional, :output => :optional, :verbose => :boolean
                   
    def build(target_name)
      require 'json'
      
      apply_build_numbers!
      requires_project!
      requires_target!(target_name)

      language = options['language'] || target.config.preferred_language
      self.manifest = target.manifest_for(:language => language)
      build!
      
      output = options['output']
      output = output.nil? ? STDOUT : File.open(output, 'w+')
      output.write JSON.pretty_generate(self.manifest.to_hash)
      output.close
      return 0
    end
    
    desc "build_number TARGET", "calculates a build number for a target"
    method_options :project => :optional, :build => :optional, :verbose => :boolean
    def build_number(target_name)

      apply_build_numbers! # if build numbers were included, put into env

      # Next, get the project & target then get the build number...
      requires_project!
      requires_target!(target_name)
      
      # Finally compute the build number
      STDOUT << self.class.build_number(self.target)
      return 0
    end

    # Computes the build number for a particular src_root
    def self.build_number(target)
      target.prepare_build_number!
    end

    def apply_build_numbers!
      return if (build = options['build']).nil?
      build_numbers = {}
      build.split(',').each do |key_code|
        target_name, build_number = key_code.split(':')
        if build_number.nil?
          SC.env.build_number = target_name
        else
          target_name = target_name.to_s.sub(/^([^\/])/,'/\1').to_sym
          build_numbers[target_name] = build_number
        end
      end
      SC.env.build_numbers = build_numbers if build_numbers.size > 0
    end
      
    # main entry point.  This method is called right after any options are 
    # processed to actually perform transforms on the manifest.  The 
    # default behavior simply calls out to several other transform methods 
    # in the following order:
    #
    #  catalog_entries:: simply catalogs every source entry
    #  localize:: applies localization settings
    #  prepare_javascript:: generates javascript entries
    #  prepare_stylesheets:: generates stylesheet entries
    #  prepare_html:: generates index.html for app targets.
    def build!
      manifest.prepare!
      catalog_entries
      localize
    end
    
    # Adds a copyfile entry for every file in the source root
    def catalog_entries
      source_root = manifest.source_root
      Dir.glob(File.join(source_root, '**', '*')).each do |path|
        next if !File.exist?(path) || File.directory?(path)
        next if target.target_directory?(path)
        filename = path.sub /^#{source_root}\//, ''
        manifest.add_entry filename # entry:prepare will fill in the rest
      end
    end
    
    def localize
    end
    
    # finds the installed languages for a particular target.
    def installed_languages_for(target)
      return %w(en)
    end
    
  end
end
