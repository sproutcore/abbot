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
        eval "@content_for_#{name} = (@content_for_#{name} || '') + (capture(&block) || '')"
      end

    end
  end
end
