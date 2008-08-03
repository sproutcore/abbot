require 'yaml'

module SproutCore

  # A Bundle Manifest describes all of the resources in a bundle, including
  # mapping their source paths, destination paths, and urls.
  #
  # A Bundle will create a manifest for every language you request from it.
  # If you invoke reload! on the bundle, it will dispose of its manifests and
  # rebuild them.
  #
  class BundleManifest

    CACHED_TYPES = [:javascript, :stylesheet, :fixture, :test]
    SYMLINKED_TYPES = [:resource]

    attr_reader :bundle, :language, :build_mode

    def initialize(bundle, language, build_mode)
      @bundle = bundle
      @language = language
      @build_mode = build_mode
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
    # out the files that don't actually belong in the current language
    def catalog_entries

      # Entries arranged by resource filename
      entries = {}
      default_lproj_entries = {}
      target_lproj_entries = {}

      # Get the name of the lproj dirs for the default and current languages
      default_lproj = bundle.lproj_for(bundle.preferred_language)
      target_lproj = bundle.lproj_for(language)

      # Any files living in the two lproj dirs will be shunted off into these arrays
      # and processed later to make sure we process them in the right order
      default_lproj_files = []
      target_lproj_files = []

      # Now, glob all the files and sort through them
      old_wd = Dir.getwd; Dir.chdir(bundle.source_root)
      Dir.glob(File.join('**','*')).each do | src_path |

        # Get source type.  Skip any without a useful type
        next if (src_type = type_of(src_path)) == :skip

        # Get current lproj (if there is one).  Skip if not default or current
        if current_lproj = src_path.match(/^([^\/]+\.lproj)\//).to_a[1]
          next if (current_lproj != default_lproj) && (current_lproj != target_lproj)
        end

        # OK, pass all of our validations.  Go ahead and build an entry for this
        # Add entry to list of entries for appropriate lproj if localized
        entry = build_entry_for(src_path, src_type)
        case current_lproj
        when default_lproj
          default_lproj_entries[entry.filename] = entry
        when target_lproj
          target_lproj_entries[entry.filename] = entry
        else

          # Be sure to mark any
          entries[entry.filename] = entry
        end
      end
      Dir.chdir(old_wd) # restore wd

      # Now, new in default and target lproj entries.  This will overwrite entries that exist
      # in both places.
      entries.merge!(default_lproj_entries)
      entries.merge!(target_lproj_entries)

      # Finally, entries will need to be grouped by type to allow further processing.
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
      when /^tests\/.+/
        :test
      when /^fixtures\/.+\.js$/
        :fixture
      when /^debug\/.+\.js$/
        :debug
      when /\.rhtml$/
        :html
      when /\.html.erb$/
        :html
      when /\.css$/
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
    def build_entry_for(src_path, src_type, composite=nil, hide_composite = true)
      ret = ManifestEntry.new
      ret.ext = File.extname(src_path)[1..-1] || '' # easy stuff
      ret.type = src_type
      ret.original_path = src_path
      ret.hidden = false
      ret.language = language

      # the filename is the src_path less any lproj in the front
      ret.filename = src_path.gsub(/^[^\/]+.lproj\//,'')

      # the source path is just the combine source root + the path
      ret.source_path = (composite.nil?) ? File.join(bundle.source_root, src_path) : nil

      # set the composite property.  The passed in array should contain other
      # entries if hide_composite is true, then hide the composite items as
      # well
      unless composite.nil?
        composite.each { |x| x.hidden = true } if hide_composite
        
        # IMPORTANT:  The array of composite entries passed in here can come
        # directly from the entries hash, which will later be updated to 
        # include the composite entry (ret) itself.  Dup the array here to 
        # make sure the list of composites maintained here does not change.
        ret.composite = composite.dup 
      end

      # The build path is the build_root + the filename
      # The URL is the url root + the language code + filename
      # also add in _cache or _sym in certain cases.  This is just more
      # efficient than doing it later.
      url_root = (src_path == 'index.html') ? bundle.index_root : bundle.url_root
      cache_link = nil
      use_source_directly =false

      # Note: you can only access real resources via the cache.  If the entry
      # is a composite then do not go through cache.
      if (self.build_mode == :development) #&& composite.nil?
        cache_link = '_cache' if CACHED_TYPES.include?(src_type)
        use_source_directly = true if SYMLINKED_TYPES.include?(src_type)
      end

      ret.use_source_directly = use_source_directly
      if use_source_directly
        ret.build_path = File.join(bundle.build_root, '_src', src_path)
        ret.url = [url_root, '_src', src_path].join('/')
      else
        ret.build_path = File.join(*[bundle.build_root, language.to_s, cache_link, ret.filename].compact)
        ret.url = [url_root, language.to_s, cache_link, ret.filename].compact.join('/')
      end

      # Done.
      return ret
    end

    # Lookup the timestamp on the source path and interpolate that into the filename URL.
    # also insert the _cache element.
    def setup_timestamp_token(entry)
      timestamp = entry.timestamp
      extname = File.extname(entry.url)
      entry.url = entry.url.gsub(/#{extname}$/,"-#{timestamp}#{extname}") # add timestamp

      extname = File.extname(entry.build_path)
      entry.build_path = entry.build_path.gsub(/#{extname}$/,"-#{timestamp}#{extname}") # add timestamp
    end
  end

  # describes a single entry in the Manifest:
  #
  # filename::     path relative to the built language (e.g. sproutcore/en) less file extension
  # ext::          the file extension
  # source_path:: absolute paths into source that will comprise this resource
  # url::          the url that should be used to reference this resource in the current mode.
  # build_url::    the url that will be used to referene this resource in production.
  # build_path::   absolute path to the compiled resource
  # type::         the top-level category
  # original_path:: save the original path used to build this entry
  # hidden::       if true, this entry is needed internally, but otherwise should not be used
  # use_source_directly::  if true, then this entry should be handled via the build symlink
  # language::     the language in use when this entry was created
  # composite::    If set, this will contain the filenames of other resources that should be combined to form this resource.
  #
  class ManifestEntry < Struct.new(:filename, :ext, :source_path, :url, :build_path, :type, :original_path, :hidden, :use_source_directly, :language)
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
        ret = (!File.exists?(source_path)) ? nil : File.mtime(source_path)
      end
      return @source_path_mtime = ret 
    end

    # Returns a timestamp based on the source_path_mtime.  If source_path_mtime is nil, always
    # returns a new timestamp
    def timestamp
      (source_path_mtime || Time.now).to_i.to_s
    end

    # Returns the content type for this entry.  Based on a set of MIME_TYPES borrowed from Rack
    def content_type
      MIME_TYPES[File.extname(build_path)[1..-1]] || 'text/plain'
    end

    # Returns a URL that takes into account caching requirements.
    def cacheable_url
      [url, timestamp].compact.join('?')
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
    }
    # :startdoc:

  end

end
