# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC

  # TaskAguments manage the arguments passed to a task.  Borrowed from Rake
  # 0.8.3
  #
  class TaskArguments
    include Enumerable

    attr_reader :names

    # for compatibility with normal TaskArguments
    def self.new(keys, values, parent = nil)
      args = super
      args.setup_with_arrays(keys, values, parent)
      args
    end

    def self.with_hash(hash)
      args = allocate
      args.setup_with_hash(hash)
      args
    end

    def setup_with_hash(hash)
      @names  = hash.keys
      @parent = nil
      @hash   = hash
    end

    # Create a TaskArgument object with a list of named arguments
    # (given by :names) and a set of associated values (given by
    # :values).  :parent is the parent argument object.
    def setup_with_arrays(keys, values, parent=nil)
      @names  = keys
      @parent = parent
      @hash   = {}

      names.each_with_index { |name, i|
        @hash[name.to_sym] = values[i] unless values[i].nil?
      }
    end

    # Create a new argument scope using the prerequisite argument
    # names.
    def new_scope(names)
      values = names.collect { |n| self[n] }
      self.class.new(names, values, self)
    end

    # Find an argument value by name or index.
    def [](index)
      lookup(index.to_sym)
    end

    # Specify a hash of default values for task arguments. Use the
    # defaults only if there is no specific value for the given
    # argument.
    def with_defaults(defaults)
      @hash = defaults.merge(@hash)
    end

    def each(&block)
      @hash.each(&block)
    end

    def method_missing(sym, *args, &block)
      lookup(sym.to_sym)
    end

    def to_hash
      @hash
    end

    def to_s
      @hash.inspect
    end

    def inspect
      to_s
    end

    protected

    def lookup(name)
      if @hash.has_key?(name)
        @hash[name]
      elsif ENV.has_key?(name.to_s)
        ENV[name.to_s]
      elsif ENV.has_key?(name.to_s.upcase)
        ENV[name.to_s.upcase]
      elsif @parent
        @parent.lookup(name)
      end
    end
  end

  EMPTY_TASK_ARGS = TaskArguments.new([], [])

end
