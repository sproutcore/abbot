require 'yaml'

module SproutCore
  
  # Describes a single library that can contain one or more clients and 
  # frameworks. This class is used to automatically locate all installed 
  # libraries and to register the clients within them.
  # 
  # Libraries are chained, with the child library replacing the parent 
  # library's settings. In general, the root library is always the current app 
  # while its parent libraries are those found in the load path or explicitly 
  # stated in the configs.
  class Library

    # Creates a chained set of libraries from the passed location and the load path
    def self.library_for(root_path, opts = {})
      
      # Find libraries in the search paths, build chain
      root_path = File.expand_path(root_path)
      paths = libraries_in($:).reject { |x| x == root_path }
      paths.unshift(root_path)
      ret = nil
      
      # Convert chain to library objects.  The last path processed should be
      # the one passed in to this method.
      while path = paths.pop 
        ret = self.new(path, opts, ret)
      end
      
      # Return library object for root_path
      return ret 
    end
    
    # Searches the array of paths, returning the array of paths that are actually libraries.
    #
    # ==== Params
    # paths<Array>:: Array of libraries.
    #
    def self.libraries_in(paths)
      ret = paths.map do |p|
        p = File.expand_path(p) # expand
        [p, p.gsub(/\/lib$/,'')].reject { |x| !is_library?(x) }
      end
      ret.flatten.compact.uniq
    end
    
    # Heuristically determine if a particular location is a library.
    def self.is_library?(path)
      has_it = %w(clients frameworks sc-config.rb).map do |x|
        File.exists?(File.join(path, x))
      end
      return false unless has_it.pop
      has_it.each { |x| return true if x }
      return false
    end
    
    # The root path for this library
    attr_reader :root_path
    
    # The raw environment hash loaded from disk.  Generally use computed_environment,
    # which combines the parent.
    attr_reader :environment
    
    # The parent library, used for load order dependency
    attr_accessor :next_library
    
    # Any proxy info stored for development
    attr_accessor :proxies
    
    # The client directories found in this library.  This usually maps directly to a 
    # client name but it may not if you have set up some other options.
    def client_directories
      return @client_dirs unless @client_dirs.nil?
      client_path = File.join(@root_path, 'clients') 
      if File.exists?(client_path)
        @client_dirs = Dir.entries(client_path).reject do |x| 
          (/^\./ =~ x) || !File.directory?(File.join(client_path,x))
        end
      else
        @client_dirs = []
      end
      
      return @client_dirs
    end

    # The framework directories found in this library
    def framework_directories
      return @framework_dirs unless @framework_dirs.nil?
      framework_path = File.join(@root_path, 'frameworks') 
      if File.exists?(framework_path)
        @framework_dirs = Dir.entries(framework_path).reject do |x| 
          (/^\./ =~ x) || !File.directory?(File.join(framework_path,x))
        end
      else
        @framework_dirs = []
      end
      
      return @framework_dirs
    end

    # Returns all of the client names known to the current environment, including 
    # through parent libraries.
    def client_names
      return @cache_client_names unless @cache_client_names.nil?
      
      ret = next_library.nil? ? [] : next_library.client_directories
      ret += client_directories
      return @cache_client_names = ret.compact.uniq.sort
    end
    
    # Returns all of the framework names known to the current environment, including
    # through parent libraries.
    def framework_names
      return @cache_framework_names unless @cache_framework_names.nil?
      
      ret = next_library.nil? ? [] : next_library.framework_directories
      ret += framework_directories
      return @cache_framework_names = ret.compact.uniq.sort
    end  
    
    # ==== Returns
    # A hash of all bundle names mapped to root url.  This method is optimized for frequent
    # requests so you can use it to route incoming requests.
    def bundles_grouped_by_url
      return @cached_bundles_by_url unless @cached_bundles_by_url.nil?
      ret = {}
      bundles.each { |b| ret[b.url_root] = b; ret[b.index_root] = b }
      return @cached_bundles_by_url = ret
    end
    
    # ==== Returns
    # A bundle for the specified name.  If the bundle has not already been created, then
    # it will be created.
    def bundle_for(bundle_name)
      bundle_name = bundle_name.to_sym
      @bundles ||= {}
      return @bundles[bundle_name] ||= Bundle.new(bundle_name, environment_for(bundle_name))      
    end
    
    # ==== Returns 
    # All of the bundles for registered clients
    def client_bundles
      @cached_client_bundles ||= client_names.map { |x| bundle_for(x) }
    end

    # ==== Returns 
    # All of the bundles for registered frameworks
    def framework_bundles
      @cached_framework_bundles ||= framework_names.map { |x| bundle_for(x) }
    end
    
    # ==== Returns
    # All known bundles, both framework & client
    def bundles
      @cached_all_bundles ||= (client_bundles + framework_bundles)
    end

    # Reloads the manifest for all bundles.
    def reload_bundles!
      bundles.each { |b| b.reload! }  
    end
    
    # Build all of the bundles in the library.  This can take awhile but it is the simple
    # way to get all of your code onto disk in a deployable state
    def build(*languages)
      (client_bundles + framework_bundles).each do |bundle|
        bundle.build(*languages)
      end
    end
    
    # Returns the computed environment for a particular client or framework.
    # This will go up the chain of parent libraries, retrieving and merging 
    # any known environment settings.  The returned options are suitable for 
    # passing to the ClientBuilder for registration.
    def environment_for(bundle_name)

      is_local_client = client_directories.include?(bundle_name.to_s)
      is_local_framework = framework_directories.include?(bundle_name.to_s)
      ret = nil
      
      # CASE 1: If named client or framework is local, then use our local settings
      if (is_local_client || is_local_framework)
        
        # start with local environment
        ret = (environment[:all] || {}).dup
        
        # Now fill in some default values based on what we know
        # This should be enough to make the bundle load
        ret[:bundle_name] = bundle_name.to_sym
        ret[:bundle_type] = is_local_framework ? :framework : :client
        ret[:requires] = [:prototype, :sproutcore] if ret[:requires].nil?
        
        # Fill in the source_root since we know where this came from
        ret[:source_root] = File.join(root_path, ret[:bundle_type].to_s.pluralize, bundle_name.to_s)
          
      # CASE 2: Otherwise, if we have a next library, see if the next library has something
      else 
        ret = next_library.nil? ? nil : next_library.environment_for(bundle_name)
      end

      # Final fixup
      unless ret.nil?
        # Always url_prefix & index_prefix are always used.
        all = environment[:all] || {}
        [:url_prefix, :all_prefix, :preferred_language].each do |key|
          ret[key] = all[key] if all.include?(key)
        end
      
        # Either way, if we have local settings for this specific client, they 
        # override whatever we cooked up just now.
        local_settings = environment[bundle_name.to_sym] 
        ret = ret.merge(local_settings) unless local_settings.nil?

        # Always replace the library with self so that we get the correct root location for
        # public paths, etc. 
        ret[:library] = self
      end
      
      
      # CASE 3: Next library doesn't know about this client.  Neither do we.  Even if the
      # user has provided some environmental options, there is no source content, so just 
      # return nil
      return ret 
    end

    # Returns a re-written proxy URL for the passed URL or nil if no proxy
    # is registered.  The URL should NOT include a hostname.
    # 
    # === Returns
    # the converted proxy_url and the proxy options or nil if no match
    #
    def proxy_url_for(url) 
      
      # look for a matching proxy.
      matched = nil
      matched_url = nil
      
      @proxies.each do |proxy_url, opts|
        matched_url = proxy_url
        matched = opts if url =~ /^#{proxy_url}/
        break if matched
      end
      
      # If matched, rewrite the URL
      if matched
        
        # rewrite the matched_url if needed...
        if matched[:url]
          url = url.gsub(/^#{matched_url}/, matched[:url])
        end
        
        # prepend the hostname and protocol 
        url = [(matched[:protocol] || 'http'), '://', matched[:to], url].join('')
        
      # otherwise nil
      else 
        url = nil
      end
      
      return [url, matched]
      
    end
      
    protected
    
    # Load the library at the specified path.  Loads the sc-config.rb if it 
    # exists and then detects all clients and frameworks in the library.  If 
    # you pass any options, those will overlay any :all options you specify in 
    # your sc-config file.
    # 
    # You cannot create a library directly using this method.  Instead is 
    # library_in()
    #
    def initialize(rp, opts = {}, next_lib = nil)
      @root_path = rp
      @next_library = next_lib
      @load_opts = opts
      @proxies = {}
      load_environment!(opts)
    end
    
    # Internal method loads the actual environment.  Get the ruby file and
    # eval it in the context of the library object.
    def load_environment!(opts=nil)
      env_path = File.join(root_path, 'sc-config.rb')
      @environment = {}
      if File.exists?(env_path)
        f = File.read(env_path)
        eval(f) # execute the config file as if it belongs.
      end
      
      # Override any all options with load_opts
      (@environment[:all] ||= {}).merge!(@load_opts)
      
    end

    # This can be called from within a configuration file to actually setup
    # the environment.  Passes the relative environment hash to the block.
    #
    # ==== Params
    # bundle_name: the bundle these settings are for or :all for every bundle.
    # opts: optional set of parameters to merge into this bundle environment
    # 
    # ==== Yields
    # If block is given, yield to the block, passing an options hash the block
    # can work on.
    #
    def config(bundle_name, opts=nil)
      env = @environment[bundle_name.to_sym] ||= {}
      env.merge!(opts) unless opts.nil?
      yield(env) if block_given?
    end
    
    # Adds a proxy to the local library.  This does NOT inherit from parent
    # libraries.
    #
    # ==== Params
    # url: the root URL to match
    # opts: options.
    #
    # ==== Options
    # :to: the new hostname
    # :url: an optional rewriting of the URL path as well.
    #
    def proxy(url, opts={})
      @proxies[url] = opts
    end
      
  end
  
end

  