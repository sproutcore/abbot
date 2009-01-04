
module Abbot
  
  class Library < Bundle
    
    # === Returns
    # paths from the array of paths that represent bundles
    def self.bundle_paths_from(paths)
      # For any paths ending in lib, go up one level also..
      paths += paths.map { |p| p.gsub(/\/lib$/,'') }
      paths.uniq.reject { |p| !self.is_bundle?(p) }
    end
    
    # Loads a library at the passed location.  In addition to creating a
    # bundle for the passed library, it will also load any bundles in the 
    # path.
    #
    # ==== Params
    #  path:: the path for the library
    # 
    # ==== Options
    #  :paths:: optional paths to search for built-in bundles.  Only needed 
    #   for testing.
    #
    def self.library_for(path, opts={})
      paths = bundle_paths_from(opts[:paths] || $:)
      idx = paths.size
      bundle = nil
      
      # first create bundles for all bundles found in the path...
      while (idx = idx-1) >= 0
        next_bundle = self.new :source_root => paths[idx], 
          :bundle_type => :library, :next_library => bundle
        bundle = next_bundle
      end        
      
      # now create target bundle
      self.new :source_root => path, 
        :bundle_type => :library, :next_library => bundle
    end
    
    def bundle_for(bundle_name)
      bundles_by_name[bundle_name.to_sym]
    end

    # Override built in bundle to deal with next library...
    def merged_sc_config
      @merged_sc_config ||= Config.merge_config(next_library.nil? ? nil : next_library.merged_sc_config, local_sc_config)
    end
        
    # Returns the next library in the current library history.
    def next_library; @next_library; end
    
    # Returns the buildfile from the next library
    def next_buildfile
      next_library.nil? ? nil : next_library.buildfile
    end
    
    def initialize(opts={}) 

      # Ignore useless options...
      opts[:bundle_type] = :library
      opts[:parent_bundle] = nil 
      super(opts)

      # set next_library...
      @next_library = opts[:next_library]

    end
    
    protected

    # Returns a hash of all bundles keyed by bundle name.
    def bundles_by_name
      return @bundles_by_name unless @bundles_by_name.nil?
      ret = @bundles_by_name = {}
      
      library = self 
      while !library.nil?
        library.all_bundles.each do |cur|
          ret[cur.bundle_name] = cur if ret[cur.bundle_name].nil?
        end
        library = library.next_library
      end
      
      return ret
    end
    
  end

end