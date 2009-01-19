require 'fileutils'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::CombineJavaScript < Builder
    
    def build(dst_path)
    end

    def ordered_entries
      return @ordered_entries unless @ordered_entries.nil?

      # first sort entries by filename, ignoring case
      sorted = entry.source_entries.sort do |a,b| 
        a.filename.downcase <=> b.filename.downcase
      end

      # now process each entry to handle requires
      seen = [] 
      ret = [] 
      while cur = next_entry(sorted)
        add_entry_to_set(cur, ret, seen, sorted)
      end
      
      # done!
      @ordered_entries = ret
    end
    
  end
  
end
