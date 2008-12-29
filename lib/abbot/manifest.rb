module Abbot
  
  class Manifest
    
    attr_reader :bundle
    attr_reader :entries
    
    def initialize(bundle)
      @bundle = bundle 
    end
    
    # Runs the 'abbot:manifest:prepare' filter on the receiver
    def prepare!
      bundle.filter_for(:'abbot:manifest:prepare').filter!(self)
    end
    
  end
  
end
