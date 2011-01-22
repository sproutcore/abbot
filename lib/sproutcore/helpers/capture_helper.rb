# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  module Helpers

    module CaptureHelper

      # Captures the resulting value of the block and returns it
      def capture(*args, &block)
        self.renderer ? self.renderer.capture(args, &block) : block.call(*args).to_s
      end

      # executes the passed block, placing the resulting content into a variable called
      # @content_for_area_name.  You can insert this content later by including this
      # variable or by calling yield(:area_name)
      #
      def content_for(name, &block)
        eval "@content_for_#{name} = (@content_for_#{name} || '') + (capture(&block) || '')", binding, __FILE__, __LINE__
        return '' # incase user does <%= content_for ... %>
      end

    end
  end
end
