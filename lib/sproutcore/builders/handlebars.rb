# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require "fileutils"
require "json"

module SC

  class Builder::Handlebars < Builder::Base

    def readlines(src_path)
      if File.exist?(src_path) && !File.directory?(src_path)
        File.read(src_path)
      else
        ""
      end
    end

    def build(dst_path)
      template_name = entry.rootname[/^.*\/([^\/]*)$/, 1]
      writelines dst_path, "SC.TEMPLATES[#{template_name.inspect}] = SC.Handlebars.compile(#{readlines(entry[:source_path]).to_json});"
    end
  end

end

