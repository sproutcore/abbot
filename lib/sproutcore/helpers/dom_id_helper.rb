# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC
  module Helpers

    module DomIdHelper
      @@tick = 0

      def dom_id!(type="id")
        @@tick += 1
        return "#{type}_#{(Time.now.to_i + @@tick)}"
      end
    end

  end
end