# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This build is used to process a single JSON file. It will substitute static_url
  # and the like as needed.
  class Builder::JSON < Builder::Base

    def build(dst_path)
      lines = read(entry[:source_path])
      replace_static_url(lines)
      writelines dst_path, lines
    end

  end

end
