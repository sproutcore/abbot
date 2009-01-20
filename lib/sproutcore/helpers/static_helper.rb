# The helper methods here are used to build the main index template file for
# a SproutCore application.  See the commented index.rhtml in the plugin for
# example usage.
#
module SC
  module Helpers

    module StaticHelper

      # This method will return the HTML to link to all the stylesheets
      # required by the named bundle.  If you pass no options, the current
      # client will be used.
      #
      # bundle_name = the name of the bundle to render or nil to use the
      # current :language => the language to render. defaults to current
      # language
      #
      def stylesheets_for_client(bundle_name = nil, opts = {})

        opts[:language] ||= language
        opts[:platform] ||= platform
        
        # Set the import method to use the standard <link> tag, if not set
        include_method = opts[:include_method] ||= :link

        # Get bundle
        cur_bundle = bundle_name.nil? ? bundle : library.bundle_for(bundle_name)

        # Convert to a list of required bundles
        all_bundles = cur_bundle.all_required_bundles

        # For each bundle, get the ordered list of stylsheet urls
        urls = []
        all_bundles.each do |b|
          urls += b.sorted_stylesheet_entries(opts).map { |x| x.cacheable_url }
        end
        all_bundles.each do |b|
          urls += b.stylesheet_libs.reject { |lib| urls.include? lib } if b.stylesheet_libs
        end

        # Convert to HTML and return
        urls = urls.map do |url|
          if include_method == :import
            %(  @import url('#{url}');)
          else
            %(  <link href="#{url}" rel="stylesheet" type="text/css" />)
          end
        end
        
        # if include style is @import, surround with style tags
        if include_method == :import
          %(<style type="text/css">\n#{urls * "\n"}</style>)
        else
          urls.join("\n")
        end
      end

      # This method will return the HTML to link to all the javascripts
      # required by the client.  If you pass no options, the current client
      # will be used.
      #
      # client_name = the name of the client to render or nil to use the
      # current :language => the language to render. defaults to @language.
      #
      def javascripts_for_client(bundle_name = nil, opts = {})

        opts[:language] ||= language
        opts[:platform] ||= platform

        # Get bundle
        cur_bundle = bundle_name.nil? ? bundle : library.bundle_for(bundle_name)

        # Convert to a list of required bundles
        all_bundles = cur_bundle.all_required_bundles

        # For each bundle, get the ordered list of stylsheet urls
        urls = []
        all_bundles.each do |b|
          urls += b.sorted_javascript_entries(opts).map { |x| x.cacheable_url }
        end
        all_bundles.each do |b|
          urls += b.javascript_libs.reject { |lib| urls.include? lib } if b.javascript_libs
        end

        # Convert to HTML and return
        urls = urls.map do |url|
          %(  <script type="text/javascript" src="#{url}"></script>)
        end

        # Add preferred language definition...
        urls << %(<script type="text/javascript">String.preferredLanguage = "#{language}";</script>)

        urls.join("\n")
      end

      # Returns the URL for the named resource
      def static_url(resource_name, opts = {})
        opts[:language] ||= language
        opts[:platform] ||= platform
        entry = bundle.find_resource_entry(resource_name, opts)
        entry.nil? ? '' : entry.cacheable_url
      end

      # Localizes the passed string, using the optional passed options.
      def loc(string, opts = {})
        string = string.nil? ? '' : string.to_s
        opts[:language] ||= language
        opts[:platform] ||= platform
        bundle.strings_hash(opts)[string] || string
      end

    end

  end
end
