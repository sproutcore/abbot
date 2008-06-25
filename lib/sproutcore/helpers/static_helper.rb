# The helper methods here are used to build the main index template file for
# a SproutCore application.  See the commented index.rhtml in the plugin for
# example usage.
#
module SproutCore
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

        # Get bundle
        cur_bundle = bundle_name.nil? ? bundle : library.bundle_for(bundle_name)

        # Convert to a list of required bundles
        all_bundles = cur_bundle.all_required_bundles

        # For each bundle, get the ordered list of stylsheet urls
        urls = []
        all_bundles.each do |b|
          urls += b.sorted_stylesheet_entries(opts).map { |x| x.url }
          urls += (b.stylesheet_libs || [])
        end

        # Convert to HTML and return
        urls = urls.map do |url|
          %(  <link href="#{url}" rel="stylesheet" type="text/css" />)
        end
        urls.join("\n")
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

        # Get bundle
        cur_bundle = bundle_name.nil? ? bundle : library.bundle_for(bundle_name)

        # Convert to a list of required bundles
        all_bundles = cur_bundle.all_required_bundles

        # For each bundle, get the ordered list of stylsheet urls
        urls = []
        all_bundles.each do |b|
          urls += b.sorted_javascript_entries(opts).map { |x| x.url }
          urls += (b.javascript_libs || [])
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
        entry = bundle.find_resource_entry(resource_name, opts)
        entry.nil? ? '' : entry.url
      end

      # Localizes the passed string, using the optional passed options.
      def loc(string, opts = {})
        opts[:language] ||= language
        bundle.strings_hash(opts)[string] || string
      end

    end

  end
end
