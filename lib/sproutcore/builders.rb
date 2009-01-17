module SproutCore
  
  # Builder classes implement the more complex algorithms for building 
  # resources in SproutCore such as building HTML, JavaScript or CSS.  
  # Builders are usually invoked from within build tasks which are, in-turn,
  # selected by the manifest.
  #
  class Builder
    
    # entry the current builder is working on
    attr_accessor :entry 
    
    def initialize(entry=nil)
      @entry =entry
    end
    
    # override this method in subclasses to actually do build
    def build(dst_path)
    end
    
    # main entry called by build tasls
    def self.build(entry, dst_path)
      new(entry).build(dst_path)
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
      lines * "\n"
    end
    
    # writes the passed lines to the named file
    def writelines(dst_path, lines)
      FileUtils.mkdir_p(File.dirname(dst_path))
      f = File.open(dst_path, 'w')
      f.write joinlines(lines)
      f.close
    end
    
    # Handles occurances of sc_static() or static_url()
    def replace_static_url(line)
      line.gsub(/(sc_static|static_url)\(\s*['"](.+)['"]\s*\)/) do | rsrc |
        static_entry = entry.manifest.find_entry($2)
        static_url(static_entry.nil? ? '' : static_entry.url)
      end
    end
      
    # Generates the proper output for a given static url and a given target
    # this is often overridden by subclasses.  the default just wraps in 
    # quotes.
    def static_url(url='')
      ['"', url.gsub('"','\"'),'"'].join('')
    end
    
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
