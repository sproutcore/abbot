# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require 'haml'

module SC
  module RenderEngine

    class Haml
      def initialize(html_context)
        @html_context = html_context
      end

      def compile(input)
        ::Haml::Engine.new(input).compiler.send(:precompiled_with_ambles, [])
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
