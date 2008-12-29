module Abbot
  
  # A ManifestFilter can be called to help build a manifest.  Before the 
  # filter is run, the required filters will first be run.
  class ManifestFilter
    
    attr_reader :filter_name # name of filter
    attr_reader :required # array of filters required before this one
    
    # Override with your subclass to do whatever filtering you want.
    def apply(manifest)
      # do nothing...
    end
    
    def filter!(manifest)
      # first, add myself to the list of filters run on this manifest
      # then make sure any required filters are run first
      manifest.applied_filters << self
      required.each do | req_filter_name |
        unless manifest.applied_filters.include(req_filter_name)
          manifest.bundle.filter_for(req_filter_name).do_filter(manifest)
        end
      end
      
      # now run my own filter code
      self.apply(manifest)
    end
      
  end
  
end
