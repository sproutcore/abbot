require 'yaml'
require 'digest/md5'

module SproutCore

  # A Bundle Manifest describes all of the resources in a bundle, including
  # mapping their source paths, destination paths, and urls.
  #
  # A Bundle will create a manifest for every language and platform you 
  # request from it. If you invoke reload! on the bundle, it will dispose of 
  # its manifests and rebuild them.
  #
  class BundleManifest

    CACHED_TYPES    = [:javascript, :stylesheet, :fixture, :test]
    SYMLINKED_TYPES = [:resource]
    
    PLATFORM_MATCH  = /^([^\/]+)\.platform\//
    LPROJ_MATCH     = /^([^\/]+\.platform\/)?([^\/]+\.lproj)\//

    NORMALIZED_TYPE_EXTENSIONS = {
      :stylesheet => { :sass => :css },
      :test => { '[^\/\.]+' => :html }
    }

    attr_reader :bundle, :language, :build_mode, :platform

    def initialize(bundle, language, build_mode, platform)
      @bundle = bundle
      @language = language
      @build_mode = build_mode
      @platform = platform
      @entries_by_type = {} # entries by type
      @entries_by_filename = {} # entries by files
      build!
    end

    def bundle_name; bundle.nil? ? nil : bundle.bundle_name; end
    
    # ==== Returns
    # All entries as an array
    #
    def entries; @entries_by_filename.values; end

    # ==== Returns
    # All of the entries matching the specified type
    #
    def entries_for(resource_type)
      @entries_by_type[resource_type] || []
    end

    # ==== Returns
    # Entry for the resource with the specified name
    #
    def entry_for(resource_name)
      @entries_by_filename[resource_name] || nil
    end

    def to_a; @entries_by_filename.values.map { |x| x.to_hash }; end
    def to_hash; @entries_by_type; end
    def to_s; @entries_by_filename.to_yaml; end

    # ==== Returns
    # true if javascripts should be combined
    def combine_javascript?
     modes = bundle.library.combine_javascript_build_modes(bundle_name)
     modes.include?(build_mode)
    end

    # ==== Returns
    # true if stylesheets should be combined
    def combine_stylesheets?
      modes = bundle.library.combine_stylesheets_build_modes(bundle_name)
      modes.include?(build_mode)
    end

    # ==== Returns
    # true if stylesheets should be combined
    def include_fixtures?
      modes = bundle.library.include_fixtures_build_modes(bundle_name)
      modes.include?(build_mode)
    end
    
    # ==== Returns
    # true if debug code should be included in the build
    def include_debug?
      modes = bundle.library.include_debug_build_modes(bundle_name)
      modes.include?(build_mode)
    end
    
    protected

    # Builds a manifest for the bundle and the specified language
    def build!

      # STEP 1: Catalog all of the files in the project, including the target
      # language and the default language.  This will filter out resources not
      # used in this language.
      entries = catalog_entries

      # STEP 2: Combine the HTML file paths into a single entry, unless this
      # is a framework
      working = entries[:html] ||= []

      if bundle.can_have_html?
        working << build_entry_for('index.html', :html, working)
      else
        working.each { |x| x.hidden = true }
      end

      # STEP 3: Handle special build modes...

      #  a. Merge fixture types into JS types if fixtures should be included
      if self.include_fixtures? && !entries[:fixture].nil?
        entries[:javascript] = (entries[:javascript] || []) + entries[:fixture]
      else
        entries.delete(:fixture)
      end

      #  b. Merge debug types into JS types if debug should be included
      if self.include_debug? && !entries[:debug].nil?
        entries[:javascript] = (entries[:javascript] || []) + entries[:debug]
      else
        entries.delete(:debug)
      end

      #  c. Rewrite all of the JS & CSS file paths and URLs to point to
      # cached versions in development mode only.
      # (Cached versions are written to _cache/filename-ctime.ext)
      if self.build_mode == :development
        (entries[:javascript] ||= []).each do | entry |
          setup_timestamp_token(entry)
        end

        (entries[:stylesheet] ||= []).each do | entry |
          setup_timestamp_token(entry)
        end
        
      #  c. Remove the entries for anything that is not JS, CSS, HTML or 
      #     Resource in non-development modes
      else
        entries.delete(:test)
      end

      #  d. Rewrite the URLs for all other resources to go through the _src 
      #     symlink 
      ## -----> Already done build_entry_for()
      
      #  STEP 4: Generate entry for combined Javascript and CSS if needed
      
      #  a. Combine the JS file paths into a single entry for the 
      #  javascript.js if required for this build mode
      hide_composite = self.combine_javascript?      
      if (working = entries[:javascript]) && working.size>0
        entry = build_entry_for('javascript.js', :javascript, working, hide_composite)
        setup_timestamp_token(entry) if self.build_mode == :development
        entry.hidden = true unless hide_composite
        working << entry
      end

      #  b. Combine the CSS file paths into a single entry for the 
      #  stylesheet.css if required for this build mode
      hide_composite = self.combine_stylesheets?
      if (working = entries[:stylesheet]) && working.size>0
        entry = build_entry_for('stylesheet.css', :stylesheet, working, hide_composite)
        setup_timestamp_token(entry) if self.build_mode == :development
        entry.hidden = true unless hide_composite
        working << entry
      end

      # Save entries into hashes
      @entries_by_type = entries
      @entries_by_filenames = {}
      entries.values.flatten.each do |entry| 
        @entries_by_filename[entry.filename] = entry
      end
    end

    # Build a catalog of entries for this manifest.  This will simply filter 
    # out the files that don't actually belong in the current language or 
    # platform
    def catalog_entries

      # Entries arranged by resource filename
      entries = {}
      default_lproj_entries = {}
      target_lproj_entries = {}

      # Get the name of the lproj dirs for the default and current languages
      default_lproj = bundle.lproj_for(bundle.preferred_language)
      target_lproj = bundle.lproj_for(language)

      # Any files living in the two lproj dirs will be shunted off into these 
      # arrays and processed later to make sure we process them in the right 
      # order
      default_lproj_files = []
      target_lproj_files = []

      # Now, glob all the files and sort through them
      old_wd = Dir.getwd; Dir.chdir(bundle.source_root)
      Dir.glob(File.join('**','*')).each do | src_path |

        # Get source type.  Skip any without a useful type
        next if (src_type = type_of(src_path)) == :skip

        # Get target platform (if there is one).  Skip is not target platform
        if current_platform = src_path.match(PLATFORM_MATCH).to_a[1]
          next if current_platform.to_sym != platform
        end
        
        # Get current lproj (if there is one).  Skip if not default or current
        if current_lproj = src_path.match(LPROJ_MATCH).to_a[2]
          next if (current_lproj != default_lproj) && (current_lproj != target_lproj)
        end

        # OK, pass all of our validations.  Go ahead and build an entry for 
        # this. Add entry to list of entries for appropriate lproj if 
        # localized.
        #
        # Note that entries are namespaced by platform.  This way non-platform
        # specific entries will not be overwritten by platfor-specific entries
        # of the same name.
        #
        entry = build_entry_for(src_path, src_type)
        entry_key = [current_platform||'', entry.filename].join(':')
        case current_lproj
        when default_lproj
          default_lproj_entries[entry_key] = entry
        when target_lproj
          target_lproj_entries[entry_key] = entry
        else

          # Be sure to mark any
          entries[entry_key] = entry
        end
      end
      Dir.chdir(old_wd) # restore wd

      # Now, merge in default and target lproj entries.  This will overwrite 
      # entries that exist in both places.
      entries.merge!(default_lproj_entries)
      entries.merge!(target_lproj_entries)

      # Finally, entries will need to be grouped by type to allow further 
      # processing.
      ret = {}
      entries.values.each { |entry| (ret[entry.type] ||= []) << entry }
      return ret
    end

    # Determines the type for this manifest entry.  Should be one of:
    #
    # stylesheet::   a CSS file
    # javascript::   a JavaScript file
    # html::         an HTML file
    #
    # test::         a test file (inside of /tests)
    # fixture::      a fixture file (inside of /fixtures)
    #
    # resource::     any other file inside an lproj dir
    # skip::      any other file outside of an lproj dir directories
    #
    # If you need to handle additional types of resources in the future, this is the place to
    # put it.
    #
    # ==== Params
    #
    # src_path:: The source path, relative to source_root.
    #
    def type_of(src_path)
      return :skip if File.directory?(src_path)
      case src_path
      when /^([^\/\.]+\.platform\/)?tests\/.+/
        :test
      when /^([^\/\.]+\.platform\/)?fixtures\/.+\.js$/
        :fixture
      when /^([^\/\.]+\.platform\/)?debug\/.+\.js$/
        :debug
      when /\.rhtml$/
        :html
      when /\.html.erb$/
        :html
      when /\.haml$/
        :html
      when /\.css$/
        :stylesheet
      when /\.sass$/
        :stylesheet
      when /\.js$/
        :javascript
      when /\.lproj\/.+/
        :resource
      else
        :skip
      end
    end

    # Build an entry for the resource at the named src_path (relative to the
    # source_root) This should assume we are in going to simply build each
    # resource into the build root without combining files, but not using our
    # _src symlink magic.
    #
    # +Params+
    #
    # src_path:: the source path, relative to the bunlde.source_root
    # src_type:: the detected source type (from type_of())
    # composite:: Array of entries that should be combined to form this or nil
    # hide_composite:: Makes composit entries hidden if !composite.nil?
    #
    # +Returns: Entry
    #
    def build_entry_for(src_path, src_type, composite=nil, hide_composite = true)
      ret = ManifestEntry.new
      ret.ext = File.extname(src_path)[1..-1] || '' # easy stuff
      ret.type = src_type
      ret.original_path = src_path
      ret.hidden = false
      ret.language = language
      ret.platform = platform
      ret.use_digest_tokens = bundle.use_digest_tokens

      # the filename is the src_path less any lproj or platform in the front
      ret.filename = src_path.gsub(LPROJ_MATCH,'')

      # the source path is just the combine source root + the path
      # Composite entries do not have a source path b/c they are generated
      # dynamically.
      ret.source_path = composite.nil? ? File.join(bundle.source_root, src_path) : nil

      # set the composite property.  The passed in array should contain other
      # entries if hide_composite is true, then hide the composite items as
      # well.  
      unless composite.nil?
        composite.each { |x| x.hidden = true } if hide_composite
        
        # IMPORTANT:  The array of composite entries passed in here can come
        # directly from the entries hash, which will later be updated to 
        # include the composite entry (ret) itself.  Dup the array here to 
        # make sure the list of composites maintained here does not change.
        ret.composite = composite.dup 
      end

      # PREPARE BUILD_PATH and URL
      
      # The main index.html file is served from the index_Root.  All other
      # resourced are served from the URL root.
      url_root = (src_path == 'index.html') ? bundle.index_root : bundle.url_root

      # Setup special cases.  Certain types of files are processed and then
      # cached in development mode (i.e. JS + CSS).  Other resources are
      # simply served up directly without any processing or building.  See
      # constants for types.
      cache_link = nil; use_source_directly =false
      if (self.build_mode == :development) #&& composite.nil?
        cache_link = '_cache' if CACHED_TYPES.include?(src_type)
        use_source_directly = true if SYMLINKED_TYPES.include?(src_type)
      end

      # If this resource should be served directly, setup both the build_path
      # and URL to point to a special URL that maps directly to the resource.
      # This is only useful in development mode
      ret.use_source_directly = use_source_directly
      if use_source_directly
        path_parts = [bundle.build_root, language.to_s, platform.to_s, '_src', src_path]
        ret.build_path = File.join(*(path_parts.compact))
        path_parts[0] = url_root
        ret.url = path_parts.compact.join('/')
        
      # If the resource is not served directly, then calculate the actual 
      # build path and URL for production mode.  The build path is the 
      # build root + language + platform + (cache_link || build_number) +
      # filename 
      #
      # The URL is the url_root + current_language + current_platform + (cache_link)
      else
        path_parts = [bundle.build_root, language.to_s, platform.to_s, 
           (cache_link || bundle.build_number.to_s), ret.filename]
        ret.build_path = File.join(*path_parts.compact)
        
        path_parts[0] = url_root
        ret.url = path_parts.compact.join('/')
        
        path_parts[3] = 'current' # create path to "current" build
        ret.current_url = path_parts.compact.join('/')
        
      end
      
      # Convert the input source type an output type.
      if sub_type = NORMALIZED_TYPE_EXTENSIONS[ret.type]
        sub_type.each do | matcher, ext |
          matcher = /\.#{matcher.to_s}$/; ext = ".#{ext.to_s}"
          ret.build_path.sub!(matcher, ext)
          ret.url.sub!(matcher, ext)
        end
      end

      # Done.
      return ret
    end

    # Lookup the timestamp on the source path and interpolate that into the 
    # filename URL and build path.  This should only be called on entries
    # that are to be cached (in development mode)
    def setup_timestamp_token(entry)
      timestamp = bundle.use_digest_tokens ? entry.digest : entry.timestamp
      
      # add timestamp or digest to URL 
      extname = File.extname(entry.url)
      entry.url.gsub!(/#{extname}$/,"-#{timestamp}#{extname}") 

      # add timestamp or digest to build path
      extname = File.extname(entry.build_path)
      entry.build_path.gsub!(/#{extname}$/,"-#{timestamp}#{extname}")
    end
  end

  # describes a single entry in the Manifest:
  #
  # filename::     path relative to the built language (e.g. sproutcore/en) less file extension
  # ext::          the file extension
  # source_path:: absolute paths into source that will comprise this resource
  # url::          the url that should be used to reference this resource in the current build mode.
  # current_url::  the url that can be used to reference this resource, substituting "current" for a build number
  # build_path::   absolute path to the compiled resource
  # type::         the top-level category
  # original_path:: save the original path used to build this entry
  # hidden::       if true, this entry is needed internally, but otherwise should not be used
  # use_source_directly::  if true, then this entry should be handled via the build symlink
  # language::     the language in use when this entry was created
  # composite::    If set, this will contain the filenames of other resources that should be combined to form this resource.
  # bundle:: the owner bundle for this entry
  # platform:: the target platform for the entry, if any
  #
  class ManifestEntry < Struct.new(:filename, :ext, :source_path, :url, :build_path, :type, :original_path, :hidden, :use_source_directly, :language, :use_digest_tokens, :platform, :current_url)
    def to_hash
      ret = {}
      self.members.zip(self.values).each { |p| ret[p[0]] = p[1] }
      ret.symbolize_keys
    end

    def composite; @composite; end
    def composite=(ary); @composite=ary; end
    
    def hidden?; !!hidden; end
    def use_source_directly?; !!use_source_directly; end
    def composite?; !!composite; end

    def localized?; !!source_path.match(/\.lproj/); end

    # Returns true if this entry can be cached even in development mode.  
    # Composite resources and tests need to be regenerated whenever you get 
    # this.
    def cacheable?
      !composite? && (type != :test)
    end

    def composite_filenames
      @composite_filenames ||= (composite || []).map { |x| x.filename }
    end
    
    # Returns the mtime of the source_path.  If this entry is a composite 
    # return the latest mtime of the items or if the source file does not 
    # exist, returns nil
    def source_path_mtime
      return @source_path_mtime unless @source_path_mtime.nil?
      
      if composite?
        mtimes = (composite || []).map { |x| x.source_path_mtime }
        ret = mtimes.compact.sort.last
      else
        ret = (File.exists?(source_path)) ? File.mtime(source_path) : nil
      end
      return @source_path_mtime = ret 
    end

    # Returns a timestamp based on the source_path_mtime.  If 
    # source_path_mtime is nil, always returns a new timestamp
    def timestamp
      (source_path_mtime || Time.now).to_i.to_s
    end

    # Returns an MD5::digest of the file.  If the file is composite, returns
    # the MD5 digest of all the composite files.
    def digest
      return @digest unless @digest.nil?
      
      if composite?
        digests = (composite || []).map { |x| x.digest }
        ret = Digest::SHA1.hexdigest(digests.join)
      else
        ret = (File.exists?(source_path)) ? Digest::SHA1.hexdigest(File.read(source_path)) : '0000' 
      end
      @digest = ret
    end
      
      
    # Returns the content type for this entry.  Based on a set of MIME_TYPES 
    # borrowed from Rack
    def content_type
      MIME_TYPES[File.extname(build_path)[1..-1]] || 'text/plain'
    end

    # Returns a URL that takes into account caching requirements.
    def cacheable_url
      url
      #token = (use_digest_tokens) ? digest : timestamp
      #[url, token].compact.join('?')
    end

    # :stopdoc:
    # From WEBrick.
    MIME_TYPES = {
      "ai"    => "application/postscript",
      "asc"   => "text/plain",
      "avi"   => "video/x-msvideo",
      "bin"   => "application/octet-stream",
      "bmp"   => "image/bmp",
      "class" => "application/octet-stream",
      "cer"   => "application/pkix-cert",
      "crl"   => "application/pkix-crl",
      "crt"   => "application/x-x509-ca-cert",
     #"crl"   => "application/x-pkcs7-crl",
      "css"   => "text/css",
      "dms"   => "application/octet-stream",
      "doc"   => "application/msword",
      "dvi"   => "application/x-dvi",
      "eps"   => "application/postscript",
      "etx"   => "text/x-setext",
      "exe"   => "application/octet-stream",
      "gif"   => "image/gif",
      "htm"   => "text/html",
      "html"  => "text/html",
      "rhtml" => "text/html",
      "jpe"   => "image/jpeg",
      "jpeg"  => "image/jpeg",
      "jpg"   => "image/jpeg",
      "lha"   => "application/octet-stream",
      "lzh"   => "application/octet-stream",
      "mov"   => "video/quicktime",
      "mpe"   => "video/mpeg",
      "mpeg"  => "video/mpeg",
      "mpg"   => "video/mpeg",
      "pbm"   => "image/x-portable-bitmap",
      "pdf"   => "application/pdf",
      "pgm"   => "image/x-portable-graymap",
      "png"   => "image/png",
      "pnm"   => "image/x-portable-anymap",
      "ppm"   => "image/x-portable-pixmap",
      "ppt"   => "application/vnd.ms-powerpoint",
      "ps"    => "application/postscript",
      "qt"    => "video/quicktime",
      "ras"   => "image/x-cmu-raster",
      "rb"    => "text/plain",
      "rd"    => "text/plain",
      "rtf"   => "application/rtf",
      "sgm"   => "text/sgml",
      "sgml"  => "text/sgml",
      "tif"   => "image/tiff",
      "tiff"  => "image/tiff",
      "txt"   => "text/plain",
      "xbm"   => "image/x-xbitmap",
      "xls"   => "application/vnd.ms-excel",
      "xml"   => "text/xml",
      "xpm"   => "image/x-xpixmap",
      "xwd"   => "image/x-xwindowdump",
      "zip"   => "application/zip",
      "js"    => "text/javascript",
      "json"  => "text/json"
    }
    # :startdoc:

  end

end
