# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC
  module Rack

    # Rewrites relevant requests to load the SproutCore docs tools for a
    # given project.
    class Docs

      def initialize(project)
        @project = project
      end

      def call(env)
        return [404, {}, "not found"]
      end
    end
  end
end
