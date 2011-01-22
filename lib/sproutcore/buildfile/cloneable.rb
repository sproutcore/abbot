# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  # Mixing for creating easily cloned objects.  Borrowed from Rake 0.8.3
  module Cloneable

    # Clone an object by making a new object and setting all the instance
    # variables to the same values.
    def dup
      sibling = self.class.new
      instance_variables.each do |ivar|
        value = self.instance_variable_get(ivar)
        new_value = value.clone rescue value
        sibling.instance_variable_set(ivar, new_value)
      end
      sibling.taint if tainted?
      sibling
    end

    def clone
      sibling = dup
      sibling.freeze if frozen?
      sibling
    end
  end


end
