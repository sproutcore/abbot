module Abbot
  module Tools
    
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
    class Manifest < ::Thor

      attr_accessor :manifest, :target, :project
      
      # Entry point for internal use.  This will create an instance, save
      # the current project, target, and manifest and then call prepare!
      #
      # === Params
      #  manifest:: the manifest to prepare
      #  
      # === Returns
      #  the prepared manifest, which should replace the one you pass in.
      #
      def self.prepare(manifest)
        tool = self.new
        tool.manifest = manifest 
        tool.target = manifest.target
        tool.project = manifest.project
        tool.prepare!
        return manifest
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
      def prepare!
        catalog_entries!
        localize!
      end
      
      # Adds a copyfile entry for every file in the source root
      def catalog_entries!
        source_root = manifest.source_root
        Dir.glob(File.join(source_root, '**', '*')).each do |path|
          next if !File.exist?(path) || File.directory?(path)
          filename = path.sub /^#{source_root}\//, ''
          manifest.add_entry filename,
            :source_path => path,
            :build_task  => :copy_file
        end
      end
      
      def localize!
      end
      
    end
    
  end
end
