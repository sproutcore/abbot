module SC
  
  # Sorts a set of entries, respecting any "requires" found in the entries.
  # To use the sorter, just call the class method EntrySorter.sort() passing
  # the entries to sort along with any filenames you prefer to have added to
  # the top.  If you don't specify any filenames, then the entries will be
  # sorted alphabetically except for requires.
  class Helpers::EntrySorter
    
    def self.sort(entries, preferred_filenames = [])
      self.new(preferred_filenames).sort(entries)
    end
    
    def initialize(preferred_filenames = [])
      @preferred_filenames = preferred_filenames
    end
    
    attr_reader :preferred_filenames
    
    def sort(entries)
      # first sort entries by filename - ignoring case
      entries = entries.sort do |a,b| 
        (a.filename || '').to_s.downcase <=> (b.filename || '').to_s.downcase
      end
       
      # now process each entry to handle requires
      seen = [] 
      ret = [] 
      while cur = next_entry(entries)
        add_entry_to_set(cur, ret, seen, entries)
      end
      
      return ret
    end

    protected
    
    # Converts a passed set of requires into entries
    def required_entries(required, entries)
      return [] if required.nil?
      required.map do |filename|
        filename = filename.to_s.downcase.ext('')
        source_filename = "source/#{filename}"
        entry = entries.find { |e| e.filename.to_s.downcase.ext('') == source_filename }
        
        # try localized version...
        if entry.nil? && !(filename =~ /^lproj\//)
          source_filename = "source/lproj/#{filename}"
          entry = entries.find { |e| e.filename.to_s.downcase.ext('') == source_filename }
        end
        
        entry
      end
    end
    
    # Returns the next entry from the set of entries based on required order.
    # Removed entry from array.
    def next_entry(entries)
      ret = nil
      
      # look for preferred entries first...
      @preferred_filenames.each do |filename|
        ret = entries.find { |e| e.filename.to_s.downcase == filename }
        break if ret
      end
      
      ret ||= entries.first # else fallback to first entry in set
      entries.delete(ret) if ret
      return ret 
    end
      
    # Adds the specified entry to the ordered array, adding required first
    def add_entry_to_set(entry, ret, seen, entries)
      return if seen.include?(entry)

      seen << entry
      required_entries(entry.required, entries).each do |required|
        next if required.nil?
        add_entry_to_set(required, ret, seen, entries)
      end
      ret << entry
    end    
    
  end
end