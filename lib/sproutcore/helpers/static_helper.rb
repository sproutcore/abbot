# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

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
        combined_entries(t, opts, 'stylesheet.css', 'stylesheet-packed.css') do |cur_target, cur_entry|
          # include either the entry URL or URL of ordered entries
          # depending on setup
          if combine_stylesheets
            urls << cur_entry.cacheable_url
          else
            urls += cur_entry.ordered_entries.map { |e| e.cacheable_url }
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
        combined_entries(t, opts, 'javascript.js', 'javascript-packed.js') do |cur_target, cur_entry|
          
          # include either the entry URL or URL of ordered entries
          # depending on setup
          if cur_target.config.combine_javascript
            urls << cur_entry.cacheable_url
          else
            urls += cur_entry.ordered_entries.map { |e| e.cacheable_url }
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

      # Detects and includes any bootstrap code
      #
      def bootstrap 
        
        ret = []
        
        # Reference any external bootstrap scripts
        if (resources_names = target.config.bootstrap)
          Array(resources_names).each do |resource_name|
            ret << %(<script src="#{sc_static(resource_name)}" type="text/javascript" ></script>)
          end
        end
        
        # Reference any inlined bootstrap scripts
        if (resources_names = target.config.bootstrap_inline)
          Array(resources_names).each do |resource_name|
            ret << inline_javascript(resource_name)
          end
        end
        
        return ret * "\n"
      end
      
      # Attempts to include the named javascript entry inline to the file
      #
      # === Options
      #  language:: the language to use.  defaults to current
      #
      def inline_javascript(resource_name, opts ={}) 

        resource_name = resource_name.to_s
        
        # determine which manifest to search.  if a language is explicitly
        # specified, lookup manifest for that language.  otherwise use 
        # current manifest.
        m = self.manifest 
        if opts[:language]
          m = target.manifest_for(:language => opts[:language]).build! 
        end
        
        entry = m.find_entry(resource_name, :entry_type => :javascript)
        if entry.nil?
          entry = m.find_entry(resource_name, :hidden => true, :entry_type => :javascript)
        end
          
        return '' if entry.nil?
        
        ret = entry.stage!.inline_contents*''
        return %(<script type="text/javascript">\n#{ret}\n</script>)
      end
     
    # Attempts to include the named javascript entry inline to the file
      #
      # === Options
      #  language:: the language to use.  defaults to current
      #
      def inline_stylesheet(resource_name, opts ={}) 

        resource_name = resource_name.to_s
        
        # determine which manifest to search.  if a language is explicitly
        # specified, lookup manifest for that language.  otherwise use 
        # current manifest.
        m = self.manifest 
        if opts[:language]
          m = target.manifest_for(:language => opts[:language]).build! 
        end
        
        entry = m.find_entry(resource_name, :entry_type => :stylesheet)
        if entry.nil?
          entry = m.find_entry(resource_name, :hidden => true, :entry_type => :stylesheet)
        end
          
        return '' if entry.nil?
        
        ret = entry.stage!.inline_contents
        return %(<style>\n#{ret*"\n"}\n</style>)
      end
        
      # Attempts to render the named entry as a partial
      #
      # === Options
      #  language:: the language to use. defaults to current
      #
      def partial(resource_name, opts = {})
        resource_name = resource_name.to_s
        m = self.manifest
        if opts[:language]
          m = target.manifest_for(:language => opts[:language]).build! 
        end

        entry = m.find_entry(resource_name, :hidden => true, :entry_type => :html)
        return entry.nil? ? '' : render_partial(entry) 
      end
        
      # Returns the URL for the named resource
      def sc_static(resource_name, opts = {})
        
        resource_name = resource_name.to_s
        
        # determine which manifest to search.  if a language is explicitly
        # specified, lookup manifest for that language.  otherwise use 
        # current manifest.
        m = self.manifest 
        if opts[:language]
          m = target.manifest_for(:language => opts[:language]).build! 
        end
        
        entry = m.find_entry(resource_name)
        return '' if entry.nil?
        return entry.friendly_url if opts[:friendly] && entry.friendly_url
        return entry.cacheable_url
      end
      alias_method :static_url, :sc_static

      # Returns the URL of the named target's index.html, if it has one
      def sc_target(resource_name, opts = {})
        opts[:friendly] = true
        resource_name = "#{resource_name}:index.html"
        sc_static(resource_name, opts)
      end
      
      # Allows you to specify HTML resource this html template should be
      # merged into.   Optionally also specify the layout file to use when
      # building this resource.
      #
      # == Example
      #   <% sc_resource :foo, :layout => 'sproutcore:lib/index.html' %>
      #
      def sc_resource(resource_name, opts = nil)
        opts = opts.nil? ? (resource_name.kind_of?(Hash) ? resource_name : {}) : opts
        @layout = opts[:layout] if opts[:layout]
        return ''
      end
        
      # Localizes the passed string, using the optional passed options.
      def loc(string, opts = {})
        string = string.nil? ? '' : string.to_s
        language = opts[:language] || self.language
        return strings_hash(language)[string] || string
      end
      
      # Returns the CSS class name dictated by the current theme.  You can
      # also pass an optional default value to use if no theme is specified
      # in the config.  The value returned here will use either the 
      # theme_name set in the target's config or the theme_name set by the
      # theme framework, if set.
      def theme_name(opts ={})
        ret = opts[:default] || 'sc-theme'
        if target.config.theme_name
          ret = target.config.theme_name
        elsif target.config.theme
          if theme_target = target.target_for(target.config.theme)
            ret = theme_target.config.theme_name || ret
          end
        end
        return ret
      end
       
      def title(cur_target=nil)
        cur_target = self.target if cur_target.nil?
        cur_target.config.title || cur_target.target_name.to_s.sub(/^\//,'').gsub(/[-_\/]/,' ').split(' ').map { |x| x.capitalize }.join(' ')
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

      # Find all of the combined entries.
      def combined_entries(t, opts, entry_name, packed_entry_name=nil, &block)
        
        # choose manifest variant.  default to current manifest variant 
        # if no explicit language was passed.
        v = opts[:language] ? { :language => opts[:language] } : manifest.variation
        
        # choose which targets to include packed and unpacked
        targets = expand_required_targets(t)
        
        if t.config.use_packed && packed_entry_name # must pass to activate
          packed, unpacked = SC::Helpers::PackedOptimizer.optimize(targets)
          unpacked << t # always use unpacked for main target
        else
          packed = []
          unpacked = targets + [t] # always use unpacked
        end
        
        # deal with packed targets...
        packed.each do |t|
          # get the manifest for the target
          cur_manifest = t.manifest_for(v).build!
          
          # get the stylesheet or js entry for it...
          entry = cur_manifest.entry_for packed_entry_name
          next if entry.nil? || !entry.composite? # no stylesheet or js
          
          yield(t, entry)
        end

        unpacked.each do |t|
          # get the manifest for the target
          cur_manifest = t.manifest_for(v).build!

          # get the stylesheet or js entry for it...
          entry = cur_manifest.entry_for entry_name
          next if entry.nil? || !entry.composite? # no stylesheet or js
          
          yield(t, entry)
        end
      end

      
    end

  end
end
