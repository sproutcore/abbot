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
        
    # Entry point for internal use.  This will instantiate the tool, build
    # and return the manifest, bypassing option processing and serialization
    # steps.  You can use this method to invoke this tool from Ruby code 
    # without paying the extra cost of running the tool externally.
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

    # Entry point for the build_number command.  This will find the build
    # number for the target based on the current config and return it.  You 
    # can use this build number or set it as needed.
    #
    # === Params
    #  target:: the target you want to find the build number for
    #
    # === Returns
    #  The build number for the target
    #
    def self.build_number(target)
      tool = self.new
      tool.targets = [target]
      tool.project = target.project
      return tool.get_build_number!
    end

    ######################################################
    # GENERAL COMMAND-LINE OPTIONS
    #

    default_build_mode :production

    method_options PROJECT_OPTIONS
    def initialize(*args)
      super
    end
    
    ######################################################
    # BUILD-NUMBER COMMAND
    #
    
    desc "build-number TARGET", "calculates a build number for a target"
    def build_number(*target_names)
      requires_targets!(*target_names)
      STDOUT << get_build_number!
      return 0
    end
    
    # Actually calculates the build number...
    def get_build_number!
      targets.first.prepare_build_number!.build_number
    end
      
      
    ######################################################
    # COMMAND LINE PROCESSING
    #

    # Entry point for a command line tool.
    desc "build [TARGET]", "generates a manifest file for the target"
    method_options :output => :optional
    def build(target_name=nil)
      return "building #{target_name}"
      
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
    

    def apply_build_numbers!
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
