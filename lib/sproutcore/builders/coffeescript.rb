# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require 'fileutils'
require 'sproutcore/builders/javascript'

module SC

  # This build can compile a Sass stylesheet.  At this point it does no
  # further processing than simply executing the Sass.  It would be nice to
  # add support for sc_static and other directives at some point.
  #
  class Builder::Coffeescript < Builder::JavaScript
    # main entry called by build tasks
    def self.build(entry, dst_path, sass_syntax=:sass)
      new(entry).build(dst_path)
    end

    def build(dst_path)
      begin
        require 'coffee-script'
      rescue LoadError => e
        raise "Cannot compile #{entry.source_path} because coffeescript is not installed.  Please install coffeescript to continue."
      end

      content = readlines(entry.source_path)
      js = CoffeeScript.compile(content)
      lines = build_lines(js)
      writelines dst_path, lines
    end # def
  end
end
