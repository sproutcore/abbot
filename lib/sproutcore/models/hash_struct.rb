# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

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

    def to_hash
      ret = {}
      each { |key, value| ret[key] = value }
      return ret
    end

    ######################################################
    # INTERNAL SUPPORT
    #

    # Pass in any options you want set initially on the manifest entry.
    def initialize(opts = {})
      super()
      self.merge!(opts)
    end

    # Allow for method-like access to hash also...
    def method_missing(id, *args)
      method_name = id.to_s
      if method_name =~ /=$/
        # suppoert property? = true
        if method_name =~ /\?=$/
          method_name = method_name[0..-3]
          value = !!args[0]
        else
          method_name = method_name[0..-2]
          value = args[0]
        end
        self[method_name] = value

      # convert property? => !!self[:property]
      elsif method_name =~ /\?$/
        !!self[method_name[0..-2].to_sym]
      else
        print_first_caller(method_name)
        self[method_name]
      end
    end

    def print_first_caller(*extras)
      first_caller = caller.find {|str| str !~ /hash_struct\.rb/ }

      unless first_caller =~ %r{spec/.*(_spec|spec_helper).rb}
        puts "---"
        p extras
        puts first_caller
        puts "---"
      end
    end

    # When using the optimized #[] lookup form,require a Symbol
    # def [](key) super end

    def []=(key, value)
      sym_key = key.to_sym rescue nil
      raise "HashStruct cannot convert #{key} to symbol" if sym_key.nil?

      super(sym_key, value)
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

