module SC
  module RenderEngine

    class Haml
      def initialize(html_context)
        @html_context = html_context
      end

      def compile(input)
        begin
          require 'haml'
        rescue
          raise "Cannot render HAML file because haml is not installed. Try running 'sudo gem install haml' and try again"
        end
        ::Haml::Engine.new(input).send(:precompiled_with_ambles, [])
      end
      
      def concat(string, binding)
        eval("_hamlout", binding).push_text string
      end
      
      def capture(*args, &block)
        if @html_context.respond_to?(:is_haml?) && @html_context.is_haml?
          @html_context.capture_haml(nil, &block)
        else
          block.call(*args).to_s
        end
      end
    end

  end
end
