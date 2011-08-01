module SproutCore
  class FileRule
    
    def initialize(exp, mode)
      @mode = mode
      @expression = Regexp.new(exp)
    end
    
    # Decides whether or not a file should be included.
    # Returns either true, false, or nil (for not a match at all)
    def include?(file)
      ret = (@mode == :deny) ? false : true
      
      if file =~ @expression
        return ret
      else
        return nil
      end
    end
    
  end
end
