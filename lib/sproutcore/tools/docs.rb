# -*- coding: utf-8 -*-
# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/tools/manifest"

module SC
  class Tools

    desc "docs [TARGET..]", "Generates JSDoc's for specified targets."
    def docs
      begin
        require 'sc_docs/cli'
        ScDocs::CLI.start
      rescue LoadError
        puts "sc-docs is no longer bundled with SproutCore. Please install the sc-docs tool instead."
      end
    end # def docs
  end # class Tools
end # module SC
