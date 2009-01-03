require 'ostruct'

module Abbot
  
  # A ManifestFilter can be called to help build a manifest.  Before the 
  # filter is run, the required filters will first be run.
  class ManifestFilter < OpenStruct
    
    attr_reader :filter_name # name of filter

    # When you create a manifest filter, you must pass at least the filter
    # name and the owner bundle where filters a defined.  You can pass any 
    # other options you would like as well and they will be added to the 
    # filter object.
    # 
    # === Params
    #  name:: The name of the filter.  Should be a symbol.
    #
    # === Options
    # :bundle:: The owner bundle.  Used to find other filters.
    # :block:: Optional proc to execute when the filter is called.
    def initialize(name, opts = {})
      opts[:filter_name] = name.to_sym
      
      super(opts)

      # Add to before/after filter
      bundle = self.bundle
      bundle.filter_for(self.before).add_before_filter(self) if self.before
      bundle.filter_for(self.after).add_after_filter(self) if self.after
      
    end

    # Override with your subclass to do whatever filtering you want.
    def apply(manifest)
      @block.call(self, manifest)
    end
    
    def filter!(manifest)
      # first, add myself to the list of filters run on this manifest
      # then make sure any required filters are run first
      manifest.applied_filters << self
      before_filters.each do | filter_name |
        unless manifest.applied_filters.include(req_filter_name)
          manifest.bundle.filter_for(req_filter_name).do_filter(manifest)
        end
      end
      
      # now run my own filter code
      self.apply(manifest)
    end
      
  end
  
end
