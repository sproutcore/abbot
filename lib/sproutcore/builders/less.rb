# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/stylesheet"
require 'fileutils'

module SC

  # This build can compile a Less stylesheet.
  class Builder::Less < Builder::Stylesheet

    def build(dst_path)
      begin
        require 'less'
      rescue
        raise "Cannot compile #{entry.source_path} because less is not installed.  Please try 'sudo gem install less' and try again"
      end

      begin
        content = read(entry.source_path)
        css = ::Less::Engine.new(content).to_css
        lines = []
        css.each_line { |l| lines << rewrite_inline_code(l) }
        writelines dst_path, lines
      rescue Exception => e

        # explain sass syntax error a bit more...
        if e.is_a? Less::SyntaxError
          e.message << " of #{@entry.source_path}"
        end
        raise e # reraise
      end # rescue
    end # def

  end

end
