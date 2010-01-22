# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'stylesheet'))
require 'fileutils'

module SC

  # This build can compile a Sass stylesheet.  At this point it does no
  # further processing than simply executing the Sass.  It would be nice to 
  # add support for sc_static and other directives at some point.
  #
  class Builder::Sass < Builder::Stylesheet
    
    def build(dst_path)
      begin
        require 'sass'
      rescue
        raise "Cannot compile #{entry.source_path} because sass is not installed.  Please try 'sudo gem install haml' and try again"
      end

      begin
        content = readlines(entry.source_path)*''
        css = ::Sass::Engine.new(content).render
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
