module SproutCore

  module Helpers

    module CaptureHelper

      # Captures the resulting value of the block and returns it
      def capture(*args, &block)
        begin
          buffer = eval('_buf', block.binding)
        rescue
          buffer = nil
        end

        if buffer.nil?
          block.call(*args).to_s
        else
          pos = buffer.length
          block.call(*args)

          # get emitted data
          data = buffer[pos..-1]

          # remove from buffer
          buffer[pos..-1] = ''

          data
        end
      end

      # executes the passed block, placing the resulting content into a variable called
      # @content_for_area_name.  You can insert this content later by including this
      # variable or by calling yield(:area_name)
      #
      def content_for(name, &block)
        eval "@content_for_#{name} = (@content_for_#{name} || '') + capture(&block)"
      end

    end

  end
end
