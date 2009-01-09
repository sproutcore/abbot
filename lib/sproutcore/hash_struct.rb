module SC
  
  # A HashStruct is a type of hash that can also be accessed as a structed
  # (like an OpenStruct).  It also treats strings and symbols as the same
  # for keys.
  class HashStruct < Hash

    # This method will provide a deep clone of the hash and its contents.
    # If any member methods also respond to deep_clone, that method will be
    # used.
    def deep_clone
      sibling = self.class.new
      self.each do | key, value |
        if value.respond_to? :deep_clone
          value = value.deep_clone
        else
          value = value.clone rescue value
        end
        sibling[key] = value
      end
      sibling
    end
    
    # Returns true if the receiver has all of the options set
    def has_options?(opts = {})
      opts.each do |key, value|
        return false if self[key] != value
      end
      return true
    end
    
    ######################################################
    # INTERNAL SUPPORT
    #

    # Pass in any options you want set initially on the manifest entry.
    def initialize(opts = {})
      super
      self.merge!(opts)
    end

    # Allow for method-like access to hash also...
    def method_missing(method_name, *args)
      if method_name.to_s =~ /=$/
        self[method_name.to_s[0..-2]] = args[0]
      else
        self[method_name]
      end
    end
    
    # Treat all keys like symbols
    def [](key)
      sym_key = key.to_sym rescue nil
      raise "HashStruct cannot convert #{key} to symbol" if sym_key.nil?
      fetch(sym_key, nil)
    end

    def []=(key, value)
      sym_key = key.to_sym rescue nil
      raise "HashStruct cannot convert #{key} to symbol" if sym_key.nil?
      store(sym_key, value)
    end

    # Reimplement merge! to go through the []=() method so that keys can be
    # symbolized
    def merge!(other_hash)
      return self if other_hash == self
      unless other_hash.nil?
        other_hash.each { |k,v| self[k] = v }
      end
      return self
    end
    
    # Reimplement to return a new HashStruct
    def merge(other_hash)
      ret = self.class.new.merge!(self)
      ret.merge!(other_hash) if other_hash != self
      return ret 
    end
    
  end
end

