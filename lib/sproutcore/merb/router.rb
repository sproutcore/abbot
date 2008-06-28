require 'sproutcore/merb/bundle_controller'

module SproutCore
  module Merb
    module RouterMethods

      # Connect a BundleController to the specified location.  All requests matching
      # this path root will by default be handled by this new controller.
      #
      # ==== Params
      # path<String>:: The root path or other matcher to use for the matcher.  This
      #  will be passed through to the router, so you can use anything you like.
      #
      # === Options
      # library:: Optional path to the library that should be hosted
      # You can also include any other options that are known to Merb::Bundle
      #
      def connect_clients(match_path, opts ={}, &block)

        # Create library
        library_root = opts.delete(:library) || opts.delete(:library_root) || ::Merb.root
        library = Library.library_for(library_root, opts)

        # Define new subclass of bundle controller
        cnt = 0
        while Object.const_defined?(class_name = "SproutCoreBundleController#{cnt}".to_sym)
          cnt += 1
        end
        klass = eval("class ::#{class_name} < SproutCore::Merb::BundleController; end; #{class_name}")

        # Register library for class in BundleController
        ::SproutCore::Merb::BundleController.register_library_for_class(library, klass)

        # Finally, register match
        return self.match(%r[^#{match_path}\/?.*]).to(:controller => "sprout_core_bundle_controller_#{cnt}", :action => 'main')

      end
    end
  end
end

# Install in router.
Merb::Router::Behavior.send(:include, SproutCore::Merb::RouterMethods)
