module SproutCore

  # This module contains entry points to builds tools that handle various types of resources
  # in a SproutCore client.  Each build tool has a method "build_xx(entry, bundle)" that can
  # be called here.
  #
  # You can add your own build tools to the system here .
  #
  module BuildTools

    # Resources are sometimes accessed through a symlink while running in 
    # devmode.  This method should simply ensure that symlink exists.
    #
    def self.build_symlink(entry, bundle)
      symlink_path = File.join(bundle.build_root, '_src')
      source_path = bundle.source_root
      unless File.exist?(symlink_path)
        FileUtils.mkdir_p(bundle.build_root)
        FileUtils.ln_sf(source_path, symlink_path)
      end
    end

    # Regular resources and tests are simply copied.  Note that normally in 
    # development mode, these resources will be accessed via a symlink
    def self.copy_resource(entry, bundle)
      FileUtils.mkdir_p(File.dirname(entry.build_path))

      # Make the source file exists
      unless File.exists?(entry.source_path)
        raise "Could not copy resource #{entry.filename} because source: #{entry.source_path} does not exist!"
      end

      # Now do the copy
      FileUtils.cp_r(entry.source_path, entry.build_path)
    end

    def self.build_resource(entry, bundle); copy_resource(entry, bundle); end

  end

end

# Load other build tools.  The above are the simple ones.
Dir.glob(File.join(File.dirname(__FILE__),'build_tools','**','*.rb')).each { |x| require x }
