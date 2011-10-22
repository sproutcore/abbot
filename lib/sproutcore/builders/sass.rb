# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/stylesheet"
require 'fileutils'

module SC

  # This build can compile a Sass stylesheet.  At this point it does no
  # further processing than simply executing the Sass.  It would be nice to
  # add support for sc_static and other directives at some point.
  #
  class Builder::Sass < Builder::Stylesheet
    @@sass_syntax = :sass

    # main entry called by build tasks
    def self.build(entry, dst_path, sass_syntax=:sass)
      @@sass_syntax =sass_syntax
      new(entry).build(dst_path)
    end

    def build(dst_path)
      begin
        require 'sass'
      rescue
        raise "Cannot compile #{entry.source_path} because sass is not installed.  Please try 'sudo gem install haml' and try again"
      end

      begin
        content = read(entry.source_path)
        load_paths = [entry.source_path[0..entry.source_path.rindex('/')]]
        css = ::Sass::Engine.new(content, :syntax => @@sass_syntax, :load_paths => load_paths).render
        lines = []
        css.each_line { |l| lines << rewrite_inline_code(l) }
        writelines dst_path, lines
      rescue Exception => e

        # explain sass syntax error a bit more...
        if e.is_a? Sass::SyntaxError
          e_string = "#{e.class}: #{e.message}"
          e_string << "\non line #{e.sass_line}"
          e_string << " of #{@entry.source_path}"
          if File.exists?(@entry.source_path)
            e_string << "\n\n"
            min = [e.sass_line - 5, 0].max
            File.read(@entry.source_path).rstrip.split("\n")[
              min .. e.sass_line + 5
            ].each_with_index do |line, i|
              e_string << "#{min + i + 1}: #{line}\n"
            end # File.read
          end # if File.exists?
          raise e_string
        else
          raise e # reraise
        end
      end # rescue
    end # def

  end

end
