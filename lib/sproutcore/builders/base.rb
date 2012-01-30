# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  # Builder classes implement the more complex algorithms for building
  # resources in SproutCore such as building HTML, JavaScript or CSS.
  # Builders are usually invoked from within build tasks which are, in-turn,
  # selected by the manifest.
  #
  module Builder

    # The base class extended by most builder classes.  This contains some
    # default functionality for handling loading and writing files.  Usually
    # you will want to consult the specific classes instead for more info.
    #
    class Base
      # entry the current builder is working on
      attr_accessor :entry

      def initialize(entry=nil)
        @entry =entry
      end

      # override this method in subclasses to actually do build
      def build(dst_path)
      end

      # main entry called by build tasks
      def self.build(entry, dst_path)
        new(entry).build(dst_path)
      end
      
      # Reads the content of the source file. If the source file does not exist,
      # returns an empty array.
      def read(src_path)
        if File.exist?(src_path) && !File.directory?(src_path)
          File.read(src_path)
        else
          ""
        end        
      end

      # Reads the lines from the source file.  If the source file does not
      # exist, returns empty array.
      def readlines(src_path)
        if File.exist?(src_path) && !File.directory?(src_path)
          File.readlines(src_path)
        else
          []
        end
      end

      # joins the array of lines.  this is where you can also do any final
      # post-processing on the build
      def joinlines(lines)
        lines.is_a?(Array) ? lines.join : lines
      end

      # writes the passed lines to the named file
      def writeline(dst_path, line)
        FileUtils.mkdir_p(File.dirname(dst_path))
        File.open(dst_path, 'w') do |f|
          f.write line
        end
      end
      
      # writes the passed lines to the named file as binary
      def writelinebinary(dst_path, line)
        FileUtils.mkdir_p(File.dirname(dst_path))
        File.open(dst_path, 'wb') do |f|
          f.write line
        end
      end
      
      # writes the passed lines to the named file
      def writelines(dst_path, lines)
        writeline(dst_path,joinlines(lines))
      end

      def sc_static_match
        /(sc_static|static_url|sc_target)\(\s*['"]([^"']*?)['"]\s*\)/
      end

      # Handles occurances of sc_static() or static_url()
      def replace_static_url(line)
        line.gsub!(sc_static_match) do | rsrc |
          entry_name = $2
          entry_name = "#{$2}:index.html" if $1 == 'sc_target'

          static_entry = entry.manifest.find_entry($2)

          if !static_entry
            SC.logger.warn "#{$2} was not found. Line: #{rsrc}"
            url = ''
          elsif $1 == 'sc_target'
            url = static_entry[:friendly_url] || static_entry.cacheable_url
          else
            url = static_entry.cacheable_url
          end

          static_url(url)
        end
      end

      # Generates the proper output for a given static url and a given target
      # this is often overridden by subclasses.  the default just wraps in
      # quotes.
      def static_url(url='')
        "'#{url.gsub('"', '\"')}'"
      end
    end # class

  end # module Builder
end # module SC
