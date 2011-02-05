# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  # InvocationChain tracks the chain of task invocations to detect
  # circular dependencies.  Borrowed from Rake 0.8.3
  class InvocationChain
    def initialize(value, tail)
      @value = value
      @tail = tail
    end

    def member?(obj)
      @value == obj || @tail.member?(obj)
    end

    def already_invoked?(task)
      (task == @value) || @tail.already_invoked?(task)
    end

    def append(value)
      if member?(value)
        raise "Circular dependency detected: #{to_s} => #{value}"
      end
      self.class.new(value, self)
    end

    def to_s
      "#{prefix}#{@value}"
    end

    def self.append(value, chain)
      chain.append(value)
    end

    private

    def prefix
      "#{@tail.to_s} => "
    end

    class EmptyInvocationChain
      def member?(obj)
        false
      end
      def append(value)
        InvocationChain.new(value, self)
      end
      def to_s
        "TOP"
      end
      def already_invoked?(task); false; end
    end

    EMPTY = EmptyInvocationChain.new

  end # class InvocationChain

end
