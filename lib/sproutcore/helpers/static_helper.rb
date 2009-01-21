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
      def stylesheets_for_client(target_name = nil, opts = nil)

        # normalize params
        if target_name.kind_of?(Hash) && opts.nil?
          opts = target_name
          target_name = nil
        end
        opts = {} if opts.nil?

        # process options
        include_method = opts[:include_method] ||= :link
        t = target_name ? target.target_for(target_name) : target

        # collect urls from entries
        urls = []
        combine_stylesheets = t.config.combine_stylesheets
        combined_entries(t, opts, 'stylesheet.css') do |cur_target, cur_entry|
          # include either the entry URL or URL of ordered entries
          # depending on setup
          if combine_stylesheets
            urls << cur_entry.url
          else
            urls += cur_entry.ordered_entries.map { |e| e.url }
          end
          
          # add any stylesheet libs from the target
          urls += (cur_target.config.stylesheet_libs || [])
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
      def javascripts_for_client(target_name = nil, opts = {})

        # normalize params
        if target_name.kind_of?(Hash) && opts.nil?
          opts = target_name
          target_name = nil
        end
        opts = {} if opts.nil?

        # process options
        t = target_name ? target.target_for(target_name) : target

        # collect urls from entries
        urls = []
        combine_javascript = t.config.combine_javascript
        combined_entries(t, opts, 'javascript.js') do |cur_target, cur_entry|
          # include either the entry URL or URL of ordered entries
          # depending on setup
          if combine_javascript
            urls << cur_entry.url
          else
            urls += cur_entry.ordered_entries.map { |e| e.url }
          end
          
          # add any stylesheet libs from the target
          urls += (cur_target.config.javascript_libs || [])
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
      def sc_static(resource_name, opts = {})
        
        # determine which manifest to search.  if a language is explicitly
        # specified, lookup manifest for that language.  otherwise use 
        # current manifest.
        m = self.manifest 
        if opts[:language]
          m = target.manifest_for(:language => opts[:language]).build! 
        end
        
        entry = m.find_entry(resource_name)
        entry.nil? ? '' : entry.url
      end
      alias_method :static_url, :sc_static

      # Allows you to specify HTML resource this html template should be
      # merged into.   Optionally also specify the layout file to use when
      # building this resource.
      #
      # == Example
      #   <% sc_resource :foo, :layout => 'sproutcore:lib/index.html' %>
      #
      def sc_resource(resource_name, opts = {})
        @layout = opts[:layout] if opts[:layout]
        return ''
      end
        
      # Localizes the passed string, using the optional passed options.
      def loc(string, opts = {})
        string = string.nil? ? '' : string.to_s
        language = opts[:language] || self.language
        return strings_hash(language)[string] || string
      end
      
      private 

      # Returns a merged strings hash from all of the required bundles.  Used
      # by loc()
      #
      # === Params
      #  for_language:: the language you want the hash for
      #
      # === Returns
      #  params hash
      #
      def strings_hash(for_language)
        ret = (@strings_hashes ||= {})[for_language]
        return ret unless ret.nil?
        
        # Need to generate hash. 
        
        # get the default manifest for the current target.  will be used to
        # select other manifests.
        m = (for_language == self.language) ? self.manifest : target.manifest_for(:language => for_language)
        
        # get all of the targets to merge...
        ret = {}
        targets = (target.expand_required_targets + [target])
        targets.each do |t|
          # get the manifest for the target
          cur_manifest = (t == target) ? m : t.manifest_for(m.variation)
          cur_manifest.build!
          
          # ...and find a strings entry, if there is one.
          strings_entry = cur_manifest.entries(:hidden => true).find { |e| e.entry_type == :strings }
          next if strings_entry.nil?

          # then load the strings
          strings_entry.stage!
          next if !File.exist?(strings_entry.staging_path) 
          strings_hash = YAML.load(File.read(strings_entry.staging_path)) 
          next if strings_hash.nil? # could not load...

          # if strings loaded, merge into ret...
          ret = ret.merge(strings_hash)
        end
        
        # save in cache.
        @strings_hashes[for_language] = ret
        return ret # done!
      end

      def combined_entries(t, opts, entry_name, &block)
        
        # choose manifest variant.  default to current manifest variant 
        # if no explicit language was passed.
        v = opts[:language] ? { :language => opts[:language] } : manifest.variation
        
        targets = (t.expand_required_targets + [t])
        targets.each do |t|
          # get the manifest for the target
          cur_manifest = t.manifest_for(v).build!
          
          # get the stylesheet entry for it...
          entry = cur_manifest.entry_for entry_name, :combined => true
          next if entry.nil? || !entry.composite? # no stylesheet...
          
          yield(t, entry)
        end
      end
        
    end

  end
end
