module SC
  module RenderEngine

    class Erubis
      def initialize(html_context)
        @html_context = html_context
      end

      def compile(input)
        begin
          require 'erubis'
        rescue
          raise "Cannot render ERB file because erubis is not installed. Try running 'sudo gem install erubis' and try again"
        end
        
        ::Erubis::Eruby.new.convert(input)
      end

      def concat(string, binding)
        eval('_buf', binding) << string
      end

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
    end

  end
end
