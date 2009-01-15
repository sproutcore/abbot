module SC
  
  class Bundle
    
    ######################################################
    ## CONSTANTS
    ##
    LONG_LANGUAGE_MAP = { :english => :en, :french => :fr, :german => :de, :japanese => :ja, :spanish => :es, :italian => :it }
    SHORT_LANGUAGE_MAP = { :en => :english, :fr => :french, :de => :german, :ja => :japanese, :es => :spanish, :it => :italian }

    # Creates a new bundle with the passed options.  You must include at 
    # least the source_root, the bundle_type, and a parent_bundle, if you
    # have one.
    #
    # The :next_bundle option is used internally to setup bundles in the load
    # path.  Normally you should not pass this option so that it can be filled
    # in for you.
    # 
    # === Options
    #  :source_root:: The path to the bundle source
    #  :bundle_type:: the bundle type.  must be :framework, :app, :library
    #  :parent_bundle:: the parent bundle.  must be included except for :library
    #
    def initialize(opts={}) 
      @source_root = opts[:source_root]
      @parent_bundle = opts[:parent_bundle]
      @bundle_type = (opts[:bundle_type] || :library).to_sym 
      @manifests = {}
      
      # ensure consistency
      raise "bundle must include source_root (opts=#{opts})" if @source_root.nil?

      if @bundle_type == :library
        raise "library bundle may not have parent bundle" if @parent_bundle
      else
        raise "#{@bundle_type} bundle must have parent bundle" if @parent_bundle.nil?
      end

    end

    ######################################################
    ## GLOBAL CONFIG
    ##
    
    # === Returns
    # true if the passed path appears to be a bundle
    def self.is_bundle?(path)
      path = SC::Buildfile.buildfile_path_for(path)
      return File.exist?(path) && !File.directory?(path)
    end
    
    ######################################################
    ## CORE PROPERTIES
    ##
    ## These are the core properties that all other extended properties are
    ## computed from.

    # Returns true only if this bundle represents a library library.  
    # Generally false
    def is_library?
      bundle_type == :library 
    end

    # The full path to the source root of the bundle
    def source_root; @source_root; end

    # Returns the library the receiver bundle belongs to
    def library; @library ||= parent_bundle.library; end
    
    # The bundle's parent bundle.  All bundles have a parent bundle except for
    # a library bundle.
    def parent_bundle; @parent_bundle; end

    # Returns the type of bundle.  Must be :library, :framework, :app
    def bundle_type; @bundle_type; end

    # The name of the bundle as it can be referenced in code.  The bundle name
    # is composed of the bundlename itself + its parent bundle name unless the
    # parent is a library.
    def bundle_name
      return @bundle_name unless @bundle_name.nil? && bundle_type != :library
      @bundle_name = File.basename(self.source_root)
      
      unless parent_bundle.nil? || parent_bundle.is_library?
        @bundle_name = [parent_bundle.bundle_name, @bundle_name].join('/')
      end
      @bundle_name = @bundle_name.to_sym
      return @bundle_name
    end 

    # Returns a buildfile instance for the bundle, combining any parent 
    # bundles.
    def buildfile
      @buildfile ||= Buildfile.load(source_root, next_buildfile)
    end
    
    # Returns the buildfile of the parent bundle (or next_library)
    def next_buildfile
      parent_bundle.nil? ? nil : parent_bundle.buildfile
    end
    
    # Returns the config for the current bundle.  The config is computed by 
    # taking the merged config settings from the build file given the current
    # build mode, then merging any environmental configs (set in SC::env)
    # over the top.
    #
    # This is the config hash you should use to control how items are built.
    def config
      return @config ||= buildfile.config_for(bundle_name, SC.build_mode).merge(SC.env)
    end
    
    ######################################################
    ## COMPUTED HELPER PROPERTIES
    ##

    # The root URL for all resources in this bundle.  Unless you specifiy
    # otherwise, this will be the library.url_prefix + bundle_name
    def url_root
      config.url_root || [library.url_prefix, bundle_name].join('/')
    end
    
    # The full path to the build root of the bundle.  Unless you specify the
    # build_root + bundle_build_root options, this will be computed from the
    # public_root + url_prefix + bundle_name
    def build_root
      config.build_root || File.join(library.public_root.to_s, library.url_prefix.to_s, bundle_name.to_s)
    end
    
    ######################################################
    ## CHILD BUNDLE METHODS
    ##

    # Returns bundles for all apps installed in this bundle
    def app_bundles
      @app_bundles ||= app_paths.map do |p| 
        Bundle.new :parent_bundle => self, :source_root => p, :bundle_type => :app
      end
    end
    
    # Returns the bundles for all frameworks installed in this bundle
    def framework_bundles
      @framework_bundles ||= framework_paths.map do |p|
        Bundle.new :parent_bundle => self, :source_root => p, :bundle_type => :framework
      end
    end
    
    # Returns all bundles installed in this bundle.  
    def child_bundles
      [app_bundles, framework_bundles].flatten.compact.sort do |a,b|
        a.source_root <=> b.source_root
      end
    end
    
    # Returns all bundles, including bundles from children and from other 
    # libraries in the load path, if there are any
    def all_bundles
      ret = [child_bundles]
      child_bundles.each { |b| ret += b.all_bundles }
      ret.flatten.compact.sort { |a,b| a.source_root <=> b.source_root }
    end

    ######################################################
    ## MANIFEST SUPPORT
    ##
      
    # The build number for the bundle.  This invokes the Buildfile
    # task bundle:compute_build_number.  If you implement this task yourself
    # you should set the build number on the BUNDLE
    def build_number
      return @build_number unless @build_number.nil?
      buildfile.invoke 'bundle:compute_build_number',
       :bundle => self, :config => self.config
      return @build_number || 'current'
    end
    
    # Set the current build number.  You should set this from within your
    # bundle:compute_build_number task
    def build_number=(build_number)
      @build_number = build_number
    end
    
    # Returns a prepared bundle manifest 
    def manifest_for(language)
      language = language.to_sym
      @manifests[language] ||= ::SC::Manifest.new(self, language).build!
    end
    
    ######################################################
    ## INTERNAL SUPPORT METHODS
    ##
    #protected 
    
    # Returns the paths for all applications installed in this bundle.
    def app_paths
      return @app_paths unless @app_paths.nil?
      
      ret = []

      # check for presence of 'clients' directory
      path = File.expand_path(File.join(source_root, 'clients'))
      ret += Dir.glob(File.join(path, '*')) if File.exist?(path)

      # check for presence of 'apps' directory
      path = File.expand_path(File.join(source_root, 'apps'))
      ret += Dir.glob(File.join(path, '*')) if File.exist?(path)
      
      @app_paths = ret.flatten.uniq.compact.sort.reject do |path|  
        !File.directory?(path)
      end
    end 

    # Returns the paths for all frameworks installed in this bundle
    def framework_paths
      return @framework_paths unless @framework_paths.nil?
      ret = []
      
      # check for presence of 'frameworks' directory
      path = File.expand_path(File.join(source_root, 'frameworks'))
      ret = Dir.glob(File.join(path, '*')) if File.exist?(path)
      ret.reject! { |path| !File.directory?(path) }

      @framework_paths = ret.flatten.uniq.compact.sort.reject do |path|  
        !File.directory?(path)
      end
    end 
    
  end
  
end
