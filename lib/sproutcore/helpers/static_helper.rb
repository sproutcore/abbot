# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

# The helper methods here are used to build the main index template file for
# a SproutCore application.  See the commented index.rhtml in the plugin for
# example usage.
#
module SC
  module Helpers

    module StaticHelper
      
      # This method will return the urls of all the stylesheets
      # required by the named bundle.
      
      # This method will return teh URLs of all the images required
      # by the named target. If no named target is provided then images
      # from all targets will be returned.
      #
      # You can filter the images that are returned using the following
      # options:
      #
      #  :language  => The language to render. Defaults to the current language
      #  :sprited   => Only those images that have been sprited by Chance
      #  :x2        => Only those images that are two-times resolution (@2x)
      #
      def image_urls_for_client(target_name=nil, opts=nil) 
        opts = {} if opts.nil?
        t = target_name ? target.target_for(target_name) : target
        v = opts[:language] ? { :language => opts[:language] } : manifest.variation
        targets = expand_required_targets(t)
        targets << t
        
        urls = []
        
        targets.each do |t|
          cur_manifest = t.manifest_for(v).build!
          cur_manifest.entries.each do |entry|
            if (entry[:entry_type] === :image)
              url = entry.cacheable_url
              url = nil if (opts[:sprited] and (url =~ /stylesheet-[-\w@]*\.png/).nil?)
              if opts[:x2]
                url = nil if (url =~ /@2x/).nil?
              else 
                url = nil if not (url =~ /@2x/).nil?
              end
              urls << url if (not url.nil?)
            end
          end
        end
        
        urls
      end

      # This method will return the HTML to link to all the stylesheets
      # required by the named bundle.  If you pass no options, the current
      # client will be used.
      #
      # bundle_name = the name of the bundle to render or nil to use the
      # current
      #
      # :language   => the language to render. defaults to current language
      # :x2         => if true, returns URLs for 2x stylesheets.
      #
      def stylesheets_for_client(target_name = nil, opts = nil)

        urls = stylesheet_urls_for_client(target_name, opts)
        
        # normalize params
        if target_name.kind_of?(Hash) && opts.nil?
          opts = target_name
          target_name = nil
        end
        opts = {} if opts.nil?
        
        # process options
        include_method = opts[:include_method] ||= :link
        
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
      
      # This method will return the urls of all the stylesheets
      # required by the named bundle.
      def stylesheet_urls_for_client(target_name = nil, opts = nil)
        
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
        combine_stylesheets = t.config[:combine_stylesheets]

        combined_entries(t, opts, 'stylesheet.css', 'stylesheet-packed.css') do |cur_target, cur_entry|
          # We have to figure out if we should use the 2x version.
          # For this, we have to figure out the original name again...
          if opts[:x2]
            name = cur_entry.filename

            name = name.gsub /stylesheet/, "stylesheet@2x"

            v = opts[:language] ? { :language => opts[:language] } : manifest.variation
            x2_entry = cur_target.manifest_for(v).entry_for name

            cur_entry = x2_entry if x2_entry
          end

          # include either the entry URL or URL of ordered entries
          # depending on setup
          if combine_stylesheets
            urls << cur_entry.cacheable_url
          else
            urls += cur_entry[:ordered_entries].map { |e| e.cacheable_url }
          end
          
          # add any stylesheet libs from the target
          urls += (cur_target.config[:stylesheet_libs] || [])
        end
        
        urls
        
      end

      # This method will return the HTML to link to all the javascripts
      # required by the client.  If you pass no options, the current client
      # will be used.
      #
      # client_name = the name of the client to render or nil to use the
      # current :language => the language to render. defaults to @language.
      #
      def javascripts_for_client(target_name = nil, opts = {})

        urls = javascript_urls_for_client(target_name, opts)

        # Convert to HTML and return
        urls = urls.map do |url|
          %(  <script type="text/javascript" src="#{url}"></script>)
        end
                
        urls.join("\n")
      end
      
      # This method will return an array of all the javascripts
      # required by the client.
      #
      # client_name = the name of the client to render or nil to use the
      # current :language => the language to render. defaults to @language.
      #
      def javascript_urls_for_client(target_name = nil, opts = {})
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
        combine_javascript = t.config[:combine_javascript]
      
        combined_entries(t, opts, 'javascript.js', 'javascript-packed.js') do |cur_target, cur_entry|
          # include either the entry URL or URL of ordered entries
          # depending on setup
          if cur_target.config[:combine_javascript]
            urls << cur_entry.cacheable_url
          elsif cur_entry[:ordered_entries]
            urls += cur_entry[:ordered_entries].map { |e| e.cacheable_url }
          end

          # add any stylesheet libs from the target
          urls += (cur_target.config[:javascript_libs] || [])
        end
        
        urls
        
      end

      # Detects and includes any bootstrap code
      #
      def bootstrap

        ret = []

        # Reference any external bootstrap scripts
        if (resources_names = target.config[:bootstrap])
          Array(resources_names).each do |resource_name|
            ret << %(<script src="#{sc_static(resource_name)}" type="text/javascript" ></script>)
          end
        end

        # Add preferred language definition, before other scripts...
        ret <<  %(<script type="text/javascript">String.preferredLanguage = "#{language}";</script>)

        # Reference any inlined bootstrap scripts
        if (resources_names = target.config[:bootstrap_inline])
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
        if target.config[:theme_name]
          ret = target.config[:theme_name]
        elsif target.config[:theme]
          if theme_target = target.target_for(target.config[:theme])
            ret = theme_target.config[:theme_name] || ret
          end
        end
        return ret
      end

      def title(cur_target=nil)
        cur_target = self.target if cur_target.nil?
        cur_target.config[:title] || cur_target[:target_name].to_s.sub(/^\//,'').gsub(/[-_\/]/,' ').split(' ').map { |x| x.capitalize }.join(' ')
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
          strings_entry = cur_manifest.entries(:hidden => true).find { |e| e[:entry_type] == :strings }
          next if strings_entry.nil?

          # then load the strings
          strings_entry.stage!
          next if !File.exist?(strings_entry[:staging_path])
          strings_hash = JSON.parse(File.read(strings_entry[:staging_path]))
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

        if t.config[:use_packed] && packed_entry_name # must pass to activate
          packed = []
          unpacked = []
          packed << t 
        else
          packed = []
          unpacked = targets + [t]
        end

        # deal with packed targets...
        packed.each do |t|
          # get the manifest for the target
          cur_manifest = t.manifest_for(v).build!

          # get the stylesheet or js entry for it...
          entry = cur_manifest.entry_for packed_entry_name
          
          if entry.nil?
            # If it didn't find it, it may have been hidden by the IE hack for splitting CSS.
            # In this case, we have to find it, but searching for any hidden file won't work
            # because there could be more than one. So, we search based on 
            entry = cur_manifest.entry_for packed_entry_name, { :hidden => true, :is_split => true  }
          end

          # It used to be like this:
          # next if entry.nil? || !entry.composite? # no stylesheet or js
          # But the @2x css file is not composite. There does not seem to be
          # a reason to check for composite entries, either. So, the composite
          # check has been removed.
          next if entry.nil? # no stylesheet or js
          
          # HACK FOR IE. Yes, IE hacks are now in Ruby as well! Isn't that grand!
          # Basically, IE does not allow more than 4096 selectors. The problem: it has
          # a max of 4096 selectors per file!!!
          #
          # and the problem is, we don't know the number of selectors until AFTER CSS
          # is built. So, we have to, at the last minute, find these other files.
          # They are given entries, but these entries are supplied AFTER the manifest
          # is technically finished. So, it is only now that we can go find them.
          #
          # In fact: it may not even be around yet. It won't until this CSS entry is built.
          # We didn't always have to build the CSS entries before serving HTML but... now we do.
          # Because IE sucks.
          entry.build!
          
          # The builder adds a :split_entries. :split_entries were added, we need to split
          # CSS files.
          if entry[:split_entries]
            entry[:split_entries].each {|e|
              yield(t, e)
            }
          else
            yield(t, entry)
          end
        end

        unpacked.each do |t|
          # get the manifest for the target
          cur_manifest = t.manifest_for(v).build!

          # get the stylesheet or js entry for it...
          entry = cur_manifest.entry_for entry_name

          # It used to be like this:
          # next if entry.nil? || !entry.composite? # no stylesheet or js
          # But the @2x css file is not composite. There does not seem to be
          # a reason to check for composite entries, either. So, the composite
          # check has been removed.
          next if entry.nil? # no stylesheet or js

          yield(t, entry)
        end
      end
    end
  end
end
