require 'sproutcore/build_tools'

module SproutCore

  # A bundle can map a directory of source files to an output format optimized
  # for delivery on the web.  It can also return the URLs to use for a
  # particular client. A Bundle cannot actually build resources for you, but
  # it works in concert with the ResourceBuilder to help you with that.
  #
  # When you create a bundle, you must pass the name of the client and the
  # library the bundle belongs to.  The library is used to generate default
  # paths for most resources and to find other bundles.
  #
  # You must provide the following properties to every build:
  #
  #  bundle_name::  A name used to identify the client for required URLs, etc.
  #  library::      The root URL of the library holding the client
  #
  # The following properties are also required, but have defaults you can rely
  # use:
  #
  #  bundle_type::       :framework|:client (default :client)
  #  required_bundles::  Names of required frameworks. (default: none)
  #  stylesheet_libs::   URLs to requires CSS not managed by the build system.
  #      (default: none)
  #  javascript_libs::   URLS to requires JavaScript notn managed by the build
  #      system (def:non)
  #
  # The following properties are required for the build process but can be
  # generated automatically using other properties you specify:
  #
  #  source_root::       The directory containing the source files
  #    default: :library_root/pluralize(:bundle_type)/:bundle_name
  #
  #  build_root::        The directory that should contain the built files.
  #    default: :public_root/:url_prefix/:bundle_name
  #
  #  url_root::          The url that can be used to reach the built resources
  #  default: /:url_prefix/:bundle_name
  #
  #  index_root::        The root url that can be used to reach retrieve the
  #  index.html. default: /:index_prefix/:bundle_name
  #
  # If you do not want to specify all of these options, you can provide the
  # following defaults and the rest will be inferred:
  #
  #  library_root::      The root URL for the library.  This is computed from
  #   the library if you pass one.
  #
  #  public_root::       The root directory accessible to the web browser.
  #    default: :library_root/public
  #
  #  url_prefix::        The prefix to put in front of all resource requests.
  #    default: static
  #
  #  index_prefix::      The prefix to put in front of all index.html request.
  #    default: ''
  #
  #  preferred_language::  The default language to use for this bundle.
  #    Defaults to :en
  #
  #  build_mode::        Determines whether the JS & CSS resources should be
  #    combined or linked directly
  #
  #  layout:        Path to the layout resource.  This should be of the form
  #    bundle_name:relative_path/to/client.  Default:
  #    sproutcore:lib/index.html
  #
  # autobuild?:    True if the bundle should be included in default builds.
  #    If set to false, then you must ASK for the bundle specifically to be
  #    built.
  #
  # use_digest_token: If true, the unique tokens adds to files will be 
  #   MD5 digests instead of timestamps.  This will ensure uniqueness when
  #   building on multiple machines.
  #
  class Bundle

    LONG_LANGUAGE_MAP = { :english => :en, :french => :fr, :german => :de, :japanese => :ja, :spanish => :es, :italian => :it }
    SHORT_LANGUAGE_MAP = { :en => :english, :fr => :french, :de => :german, :ja => :japanese, :es => :spanish, :it => :italian }

    # The default build mode for bundles.  This should be set once before you
    # start using bundles.  You can override this when you create a specific
    # bundle, but that should not be the typical behavior
    def self.build_mode; (@build_mode || :development).to_sym; end

    def self.build_mode=(new_mode); @build_mode = new_mode; end


    attr_reader :bundle_name, :bundle_type, :required_bundles, :preferred_language
    attr_reader :javascript_libs, :stylesheet_libs
    attr_reader :library, :public_root, :url_prefix, :index_prefix, :build_prefix
    attr_reader :source_root, :build_root, :url_root, :index_root
    attr_reader :build_mode, :layout
    attr_reader :make_resources_relative
    attr_reader :use_digest_tokens

    def library_root
      @library_root ||= library.nil? ? nil : library.root_path
    end

    # ==== Returns
    # All bundles required directly or indirectly by this bundles.  These are
    # returned in their proper load order.
    #
    def all_required_bundles(seen=nil)
      seen ||= Set.new
      seen << self

      ret = []
      # before you load me, load my bundles
      required_bundles.each do |name|
        b = library.bundle_for(name)
        next if seen.include?(b)
        raise "Cannot locate required bundle '#{name}' for #{bundle_name}" if b.nil?
        ret += b.all_required_bundles(seen)
      end
      ret << self
      return ret
    end

    # ==== Returns
    # True if the build_mode is not development to minify the JS.
    def minify?
      library.minify_build_modes.include?(build_mode)
    end

    # ==== Returns
    # true if this bundle should be auto-built.
    def autobuild?
      @autobuild.nil? ? true : @autobuild
    end
    
    # ==== Returns
    # The computed path to the layout rhtml.
    def layout_path
      return @layout_path unless @layout_path.nil?
      bundle_name, entry_name = layout.split(':')
      entry_name, bundle_name = bundle_name, entry_name if entry_name.nil?

      # Get the bundle.  If bundle_name is nil, self
      layout_bundle = bundle_name.nil? ? self : library.bundle_for(bundle_name.to_sym)
      return nil if layout_bundle.nil?

      # Now look for an entry with that name.  This will use the primary language
      # since we do not support localized layouts.
      entry = layout_bundle.entry_for(entry_name, :hidden => :include)

      # If the entry was not found, then we don't have a layout.  Oh no!
      if entry.nil?
        raise "Could not find layout named #{entry_name} in bundle #{layout_bundle.bundle_name}!"
      end

      # The return value if the source_path of the entry.
      @layout_path = entry.source_path
    end

    # Returns the root URL to the current library.
    def initialize(bundle_name, opts ={})

      # You must provide the following properties to every build:
      # bundle_name::       A name used to identify the client for required
      #  URLs, etc.
      @bundle_name = bundle_name.to_sym

      # The following are not required by the build system, but they can be
      # used to automatically construct the key paths listed below.  Often
      # times defaults will do the right thing
      #
      # library::      The root URL of the library holding the client
      @library = opts[:library]
      @library_root = opts[:library_root]
      raise "Bundles must belong to a library or have a library_root" if library_root.nil?

      # The following properties are also required, but have defaults you can
      # rely use:
      #  bundle_type::       :framework|:client (default :client)
      @bundle_type = (opts[:bundle_type] || opts[:type] || :client).to_sym

      #  dependencies::      Names of required frameworks. (default: :sproutapp)
      @required_bundles = opts[:required_bundles] || opts[:required] || []

      #  preferred_language::  The default language to use for this bundle.
      @preferred_language = (opts[:preferred_language] || opts[:language] || :en).to_sym

      # javacript_libs:: External required libraries.
      @javascript_libs = opts[:javascript_libs] || opts[:js_libs] || []

      # stylesheet_libs:: External required stylesheet library
      @stylesheet_libs = opts[:stylesheet_libs] || opts[:css_libs] || []

      #  public_root::       The root directory accessible to the web browser.
      @public_root = normalize_path(opts[:public_root] || 'public')

      @make_resources_relative = opts[:resources_relative] || false

      #  url_prefix::        The prefix to put in front of all resource requests.
      @url_prefix = opts[:url_prefix] || opts[:resources_at] || opts[:at] || (make_resources_relative ? '../..' : 'static')

      #  build_prefix::      The prefix to put in front of the built files directory.  Generally if you are using absolute paths you want your build_prefix to match the url_prefix.  If you are using relative paths, you don't want a build prefix.
      @build_prefix = opts[:build_prefix] || (make_resources_relative ? '' : url_prefix)

      #  index_prefix::      The prefix to put in front of all index.html request.
      @index_prefix = opts[:index_prefix] || opts[:index_at] || ''

      # The following properties are required for the build process but can be generated
      # automatically using other properties you specify:
      #  source_root::       The directory containing the source files
      @source_root = normalize_path(opts[:source_root] || File.join(bundle_type.to_s.pluralize, bundle_name.to_s))

      #  build_root::        The directory that should contain the built files.
      @build_root = normalize_path(opts[:build_root] || File.join(public_root, build_prefix.to_s, bundle_name.to_s))

      #  url_root::          The url that can be used to reach the built resources

      # Note that if the resources are relative, we don't want to include a
      # '/' at the front.  Using nil will cause it to be removed during
      # compact.
      @url_root = opts[:url_root] || [
        (make_resources_relative ? nil : ''),
        (url_prefix.nil? || url_prefix.size==0) ? nil : url_prefix,
        bundle_name.to_s].compact.join('/')

      #  index_root::        The root url that can be used to reach retrieve the index.html.
      @index_root = opts[:index_root] || ['',(index_prefix.nil? || index_prefix.size==0) ? nil : index_prefix, bundle_name.to_s].compact.join('/')

      #  build_mode::        The build mode to use when combining resources.
      @build_mode = (opts[:build_mode] || SproutCore::Bundle.build_mode || :development).to_sym

      #  layout:        Path to the layout resource.  This should be of the form
      @layout = opts[:layout] || 'sproutcore:lib/index.rhtml'

      # autobuild?:     Determines if you should autobuild...
      @autobuild = opts[:autobuild]
      @autobuild = true if @autobuild.nil?
      
      @use_digest_tokens = opts[:use_digest_tokens] || (@build_mode == :production)
      
      reload!
    end

    ######################################################
    ## RETRIEVING RESOURCES
    ##

    # ==== Returns
    # The array of stylesheet entries sorted in load order.
    def sorted_stylesheet_entries(opts = {})
      opts[:language] ||= preferred_language
      entries = entries_for(:stylesheet, opts)
      BuildTools::ResourceBuilder.sort_entries_by_load_order(entries, opts[:language], self)
    end

    # ==== Returns
    # The array of javascript entries sorted in load order.
    def sorted_javascript_entries(opts = {})
      opts[:language] ||= preferred_language
      entries = entries_for(:javascript, opts)
      BuildTools::JavaScriptResourceBuilder.sort_entries_by_load_order(entries, opts[:language], self)
    end

    # This method returns the manifest entries for resources of the specified
    # type.
    #
    # ==== Params
    # type::  must be one of :javascript, :stylesheet, :resource, :html, 3
    #  :fixture, :test
    #
    # ==== Options
    # language::  The language to use.  Defaults to preferred language.
    # hidden::    Can be :none|:include|:only
    #
    def entries_for(resource_type, opts={})
      with_hidden = opts[:hidden] || :none

      language = opts[:language] || preferred_language
      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(language, mode)

      ret = manifest.entries_for(resource_type)

      case with_hidden
      when :none
        ret = ret.reject { |x| x.hidden }
      when :only
        ret = ret.reject { |x| !x.hidden }
      end
      return ret
    end

    # Returns the manifest entry for a resource with the specified name.
    #
    # ==== Params
    # name: The name of the entry.
    #
    # ==== Options
    # language::  The language to use.  Defaults to preferred language
    # hidden::    Can be :none|:include|:only
    #
    def entry_for(resource_name, opts={})
      with_hidden = opts[:hidden] || :none

      language = opts[:language] || preferred_language
      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(language, mode)

      ret = manifest.entry_for(resource_name)

      case with_hidden
      when :none
        ret = nil if ret && ret.hidden?
      when :only
        ret = nil unless ret && ret.hidden?
      end
      return ret
    end

    # Returns the entry for the specified URL.  This will extract the language
    # from the URL and try to get the entry from both the manifest in the
    # current build mode and in the production build mode (if one is
    # provided)
    #
    # ==== Params
    # url<String>:: The url
    #
    # ==== Options
    # hidden::     Use :include,:none,:only to control hidden options
    # language::   Explicitly include the language.  Leave this out to
    #   autodetect from URL.
    #
    def entry_for_url(url, opts={})
      # get the language
      opts[:language] ||= url.match(/^#{url_root}\/([^\/]+)\//).to_a[1] || url.match(/^#{index_root}\/([^\/]+)\//).to_a[1] || preferred_language

      # use the current build mode
      opts[:build_mode] = build_mode
      entries(opts).each do |entry|
        return entry if entry.url == url
      end

      # try production is necessary...
      if (build_mode != :production)
        opts[:build_mode] = :production
        entries(opts).each do |entry|
          return entry if entry.url == url
        end
      end

      return nil # not found!
    end

    # Helper method.  This will normalize a URL into one that can map directly
    # to an entry in the bundle.  If the URL is of a format that cannot be
    # converted, returns nil.
    #
    # ==== Params
    # url<String>:: The URL
    #
    def normalize_url(url)

      # Get the default index.
      if (url == index_root)
        url = [index_root, preferred_language.to_s, 'index.html'].join('/')

      # Requests to index_root/lang should have index.html appended to them
      elsif /^#{index_root}\/[^\/\.]+$/ =~ url
        url << '/index.html'
      end

      return url
    end

    # Returns all of the entries for the manifest.
    #
    # ==== Options
    # language::  The language to use.  Defaults to preferred language
    # hidden::    Can be :none|:include|:only
    #
    def entries(opts ={})
      with_hidden = opts[:hidden] || :none

      language = opts[:language] || preferred_language
      mode = (opts[:build_mode] || build_mode).to_sym
      manifest = manifest_for(language, mode)

      ret = manifest.entries

      case with_hidden
      when :none
        ret = ret.reject { |x| x.hidden }
      when :only
        ret = ret.reject { |x| !x.hidden }
      end
      return ret
    end

    # Does a deep search of the entries, looking for a resource that is a
    # close match of the specified resource.  This does not need to match the
    # filename exactly and it can omit the extension
    def find_resource_entry(filename, opts={}, seen=nil)
      extname = File.extname(filename)
      rootname = filename.gsub(/#{extname}$/,'')
      entry_extname = entry_rootname = nil

      ret = entries_for(:resource, opts.merge(:hidden => :none)).reject do |entry|
        entry_extname = File.extname(entry.filename)
        entry_rootname = entry.filename.gsub(/#{entry_extname}$/,'')

        ext_match = (extname.nil? || extname.size == 0) || (entry_extname == extname)
        !(ext_match && (/#{rootname}$/ =~ entry_rootname))
      end

      ret = ret.first

      if ret.nil?
        seen = Set.new if seen.nil?
        seen << self
        all_required_bundles.each do |bundle|
          next if seen.include?(bundle) # avoid recursion
          ret = bundle.find_resource_entry(filename, opts, seen)
          return ret unless ret.nil?
        end
      end
      return ret
    end

    # Builds the passed array of entries.  If the entry is already built, then
    # this method does nothing unless force => true
    #
    # The exact action taken by this method varies by resource type.  Some
    # resources will simply be copied.  Others will actually be compiled.
    #
    # ==== Params
    #
    #  entries::  The entries to build
    #
    # ==== Options
    #
    # force:: If true then the entry will be built again, even if it already
    #   exists.
    # hidden:: Set to :none, :include, or :only
    #
    def build_entries(entries, opts={})

      with_hidden = opts[:hidden] || :none

      # First, start an "already seen" set.
      created_seen = @seen.nil?
      @seen ||= []

      # Now, process the entries, adding them to the seen set.
      entries.each do |entry|

        # skip if hidden, already seen, or already built (unless forced)
        if entry.hidden? && with_hidden == :none
          SC.logger.debug("~ Skipping Entry: #{entry.filename} because it is hidden") and next
        end

        if !entry.hidden? && with_hidden == :only
          SC.logger.debug("~ Skipping Entry: #{entry.filename} because it is not hidden") and next
        end

        # Nothing interesting to log here.
        next if @seen.include?(entry)
        @seen << entry

        # Do not build if file exists and source paths are not newer.
        if !opts[:force] && File.exists?(entry.build_path)
          source_mtime = entry.source_path_mtime
          if source_mtime && (File.mtime(entry.build_path) >= source_mtime)
            SC.logger.debug("~ Skipping Entry: #{entry.filename} because it has not changed") and next
          end
        end


        # OK, looks like this is ready to be built.
        # if the entry is served directly from source
        if entry.use_source_directly?
          SC.logger.debug("~ No Build Required: #{entry.filename} (will be served directly)")
        else
          SC.logger.debug("~ Building #{entry.type.to_s.capitalize}: #{entry.filename}")
          BuildTools.send("build_#{entry.type}".to_sym, entry, self)
        end
      end

      # Clean up the seen set when we exit.
      @seen = nil if created_seen
    end

    # Easy singular form of build_entries().  Take same parameters except for
    # a single entry instead of an array.
    def build_entry(entry, opts={})
      build_entries([entry], opts)
    end

    # Invoked by build tools when they build a dependent entry. This will add
    # the entry to the list of seen entries during a build so that it will not
    # be rebuilt.
    def did_build_entry(entry)
      @seen << entry unless @seen.nil?
    end

    # This will perform a complete build for the named language
    def build_language(language)
      SC.logger.info("~ Language: #{language}")
      build_entries(entries(:language => language))
      SC.logger.debug("~ Done.\n")
    end

    # This will perform a complete build for all languages that have a
    # matching lproj. You can also pass in an array of languages you would
    # like to build
    def build(*languages)

      # Get the installed languages (and the preferred language, just in case)
      languages = languages.flatten
      languages = installed_languages if languages.nil? || languages.size == 0
      languages.uniq!

      SC.logger.debug("~ Build Mode:  #{build_mode}")
      SC.logger.debug("~ Source Root: #{source_root}")
      SC.logger.debug("~ Build Root:  #{build_root}")

      languages.uniq.each { |lang| build_language(lang) }

      # After build is complete, try to copy the index.html file of the
      # preferred language to the build_root
      index_entry = entry_for('index.html', :language => preferred_language)
      if index_entry && File.exists?(index_entry.build_path)

        # If we are publishing relative resources, then the default
        # index.html needs to just redirect to the default language.
        if make_resources_relative
          index_url = index_entry.url.gsub("#{self.index_root}/",'')
          file = %(<html><head>
           <meta http-equiv="refresh" content="0;url=#{index_url}" />
           <script type="text/javascript">
            window.location.href='#{index_url}';
           </script>
           </head>
           <body><a href="#{index_url}">Click here</a> if you are not redirected.</body></html>)
          f = File.open(File.join(build_root, 'index.html'), 'w+')
          f.write(file)
          f.close

        # Otherwise, just copy the contents of the index.html for the
        # preferred language.
        else
          FileUtils.mkdir_p(build_root)
          FileUtils.cp_r(index_entry.build_path, File.join(build_root,'index.html'))
        end
      end
    end

    ######################################################
    ## RUBY HELPERS
    ##

    # ==== Returns
    # Array of path to helper files that need to be loaded into memory
    # before any HTML from the bundle can be rendered.
    #
    def helper_paths
      File.exists?(File.join(source_root,'lib')) ? Dir.glob(File.join(source_root, 'lib', '**', '*.rb')) : []
    end

    # ==== Returns
    # The helper path ending in the specified name (sans extension)
    #
    def helper_for(helper_name)
      paths = helper_paths

      ret = nil
      paths.each do |path|
        if path =~ /#{helper_name}(\.rb)?$/
          ret = path
          break
        end
      end

      return ret
    end

    # ==== Returns
    # The contents of the helper file at the specified path.  For performance
    # reasons, the contents are only loaded once and reused unless the file's
    # mtime has changed.
    def helper_contents_for(path)

      # Oops...file has been deleted!
      return '' if !File.exists?(path)

      @_cached_helper_contents ||= {}
      cached = @_cached_helper_contents[path]

      return cached[:contents] if cached && (cached[:mtime] == File.mtime(path))

      # Not cached, build it.
      cached = { :mtime => File.mtime(path), :contents => File.read(path) }
      @_cached_helper_contents[path] = cached

      return cached[:contents]
    end

    ######################################################
    ## LOCALIZATION
    ##

    # Returns all of the strings.js entries for this bundle and any required
    # bundles.  The return array is in the order the entries should be
    # processed to build the strings hash.
    #
    # ==== Options
    # language: optional language.  otherwise preferred language is used.
    #
    def strings_entries(opts = {})
      opts[:hidden] = true # include hidden files for prod mode.
      all_required_bundles.map { |q| q.entry_for('strings.js', opts) }.compact
    end

    # This will load a strings resource and convert it into a hash of key
    # value pairs.
    def strings_for_entry(strings_entry)
      source_path = strings_entry.source_path
      return {} if !File.exists?(source_path)

      # read the file in and strip out comments...
      str = File.read(source_path)
      str = str.gsub(/\/\/.*$/,'').gsub(/\/\*.*\*\//m,'')

      # Now build the hash
      ret = {}
      str.scan(/['"](.+)['"]\s*:\s*['"](.+)['"],?\s*$/) do |x,y|
        # x & y are JS strings that must be evaled as such..
        #x = eval(%("#{x}"))
        y = eval(%[<<__EOF__\n#{y}\n__EOF__]).chop
        ret[x] = y
      end

      return ret
    end

    # Strings the string hash for the current bundle.  If this strings hash
    # has not been loaded yet, it will be loaded now.
    #
    # ==== Options
    # language: optional language.  otherwise preferred language is used.
    #
    def strings_hash(opts={})

      build_mode = (opts[:build_mode] ||= self.build_mode).to_sym
      language = opts[:language] ||= preferred_language
      key = [build_mode.to_s, language.to_s].join(':').to_sym

      @strings_hash ||= {}
      if @strings_hash[key].nil?
        ret = {}
        strings_entries(opts).each do |entry|
          ret.merge! strings_for_entry(entry)
        end
        @strings_hash[key] = ret
      end

      return @strings_hash[key]
    end

    ######################################################
    ## MANIFESTS
    ##

    # Invoke this method whenever you think the bundle's contents on disk
    # might have changed this will throw away any cached information in
    # bundle.  This is generally a cheap operation so it is OK to call it
    # often, though it will be less performant overall.
    def reload!
      @manifests = {}
      @strings_hash = {}
    end

    # Returns the bundle manifest for the specified language and build mode.
    # The manifest will be created if it does not yet exist.
    def manifest_for(language, build_mode)
      manifest_key = [build_mode.to_s, language.to_s].join(':').to_sym
      @manifests[manifest_key] ||= BundleManifest.new(self, language.to_sym, build_mode.to_sym)
    end

    # ==== Returns
    # Languages installed in the source directory
    #
    def installed_languages
      ret = Dir.glob(File.join(source_root,'*.lproj')).map do |x|
        x.match(/([^\/]+)\.lproj$/).to_a[1]
      end
      ret << preferred_language
      ret.compact.map { |x| LONG_LANGUAGE_MAP[x.to_sym] || x.to_sym }.uniq
    end

    # Finds the actual lproj directory (in the source) for the language code.
    # If the named language does not exist, returns the lproj for the
    # preferred language.
    def lproj_for(language)

      # try language as passed in.
      ret = "#{language}.lproj"
      return ret if File.exists?(File.join(source_root,ret))

      # failed, try to map to long language
      if long_language = SHORT_LANGUAGE_MAP[language.to_sym]
        ret = "#{long_language}.lproj"
        return ret if File.exists?(File.join(source_root,ret))
      end

      # failed, try to map to short language
      if short_language = LONG_LANGUAGE_MAP[language.to_sym]
        ret = "#{short_language}.lproj"
        return ret if File.exists?(File.join(source_root,ret))
      end

      # failed, return using preferred_language unless this is the preferred
      # language
      ret = (language != preferred_language) ? lproj_for(preferred_language) : nil
      return ret unless ret.nil?

      # Super-ultra massive fail.  Possible that no localized resources exist
      # at all. Return english.lproj and hope for the best
      return 'english.lproj'
    end

    # Used by the bundle manifest.  Only true if bundle_type is client
    def can_have_html?
      return bundle_type == :client
    end

    protected

    # Converts the named path to a fully qualified path name using the library
    # root, if it does not begin with a slash
    def normalize_path(path)
      File.expand_path(path, library_root)
    end

  end

end
