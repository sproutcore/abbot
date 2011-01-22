# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2010 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'json'

module SC

  # If a target is a prefetched module, this builder will take the contents of its packed file
  # and wrap it in strings.
  class Builder::StringWrapper < Builder::Base

    def build(dst_path)
      entries = entry[:source_entries]

      entries.each do |entry|
        src_path = entry.stage![:staging_path]
        return if not File.exist? src_path

        # Normalize the target name by removing any initial forward slash
        target = entry.target
        target_name = target[:target_name].to_s.sub(/^\//,'')

        # Set the source property of the module's SC.MODULE_INFO hash to the
        # JSON-escaped contents of the file.
        output = "SC.MODULE_INFO['#{target_name}'].source = "

        content = readlines(src_path)
        output += content.join.to_json

        output += ";"

        writeline dst_path, output
      end
    end

  end

end
