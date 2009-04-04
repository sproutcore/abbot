# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC::Helpers
  
  # Given a set of targets, this can determine the optimial mix of loading
  # packed targets vs individual targets to yield the smaller number of 
  # assets.  To use this optimizer, just call the optimize() method.
  class PackedOptimizer
    
    # Returns two arrays:  the first array are targets that should be loaded
    # packed.  The array of targets that should be loaded, but not packed.
    # And optional third array is also returned that includes targets which
    # were passed in but are no longer needed because they are included in 
    # a packed target.
    def self.optimize(targets)
      packed = []
      unpacked = targets
      cnt = packed.size + unpacked.size
      
      # for each target, try to use the packed version and see how many
      # total items we come back with.  If the total number of targets is 
      # less than the current best option, use that instead.
      targets.each do |target|
        cur_packed, cur_unpacked = self.new.process(target, targets)
        cur_cnt = cur_packed.size + cur_unpacked.size
        if cur_cnt < cnt
          packed   = cur_packed
          unpacked = cur_unpacked
          cnt      = cur_cnt
        end
      end
      
      # return best!
      return [packed, unpacked]
    end
    
    attr_reader :packed
    attr_reader :unpacked
    
    def initialize
      @seen = []
      @packed = []
      @unpacked = []
    end
    
    # Sorts the passed array of targets into packed and unpacked, starting
    # with the passed target as the packed target.
    def process(packed_target, targets)
      # manually add in packed target...
      @seen   << packed_target
      @packed << packed_target
      packed_target.expand_required_targets.each { |t| @seen << t }
      
      # then handle the rest of the targets
      targets.each { |t| process_target(t) }
      
      return [packed, unpacked]
    end
    
    # Sorts a single target into the correct bucket based on whether it is 
    # seen or not.  If you also pass true to the second param, the required
    # targets will also be sorted.
    def process_target(target)
      # if target was seen already, nothing to do
      return if @seen.include?(target)

      # add to seen
      @seen << target
      
      # have we already seen any of the required targets?
      req_targets = target.expand_required_targets
      if req_targets.size > 0
        already_seen = req_targets.find do |t|
          @seen.include?(t)
        end
      else
        already_seen = true
      end
      
      
      # if we have seen one, then we can't use the packed version so put it
      # in the unpacked set.
      if already_seen
        req_targets.each { |t| process_target(t) }
        @unpacked << target  # add last to keep order intact
        
      # if we have not seen any required, then we can mark this as packed.
      # yeah!  mark the required targets as seen also
      else
        req_targets.each { |t| @seen << t }
        @packed << target
      end
    end
    
  end
  
end
