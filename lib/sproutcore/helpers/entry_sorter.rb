# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC
  
  module Helpers
    
    # Sorts a set of entries, respecting any "requires" found in the entries.
    # To use the sorter, just call the class method EntrySorter.sort() passing
    # the entries to sort along with any filenames you prefer to have added to
    # the top.  If you don't specify any filenames, then the entries will be
    # sorted alphabetically except for requires.
    # 
    # When bundle_info.js is present, it will always be sorted first.
    # When bundle_loaded.js is present, it will always be sorted last.
    class EntrySorter
    
      def self.sort(entries, preferred_filenames = [])
        self.new(preferred_filenames).sort(entries)
      end
    
      def initialize(preferred_filenames = [])
        @preferred_filenames = preferred_filenames
      end
    
      attr_reader :preferred_filenames
    
      def sort(entries)
        bundleInfoEntry = []
        bundleLoadedEntry = []
        
        # first remove bundle entries which MUST be first or last
        entries = entries.select do |entry|
          if entry.filename == 'bundle_info.js'
            bundleInfoEntry = [entry]
            false
          elsif entry.filename == 'bundle_loaded.js'
            bundleLoadedEntry = [entry]
            false
          else
            true
          end
        end
        
        # then sort remaining entries by filename - ignoring case
        entries = entries.sort do |a,b| 
          a = (a.filename || '').to_s.downcase
          b = (b.filename || '').to_s.downcase

          # lproj/foo_page.js and main.js are loaded last
          a_kind = (a =~ /(lproj|resources)\/.+_page\.js$/) ? 1 : -1
          a_kind = 2 if a =~ /main.js$/

          b_kind = (b =~ /(lproj|resources)\/.+_page\.js$/) ? 1 : -1
          b_kind = 2 if b =~ /main.js$/
          
          if a_kind != b_kind
            a_kind <=> b_kind
          else
            a <=> b
          end
          
        end
        all_entries = entries.dup # needed for sort...
       
        # now process each entry to handle requires
        seen = [] 
        ret = [] 
        while cur = next_entry(entries)
          add_entry_to_set(cur, ret, seen, entries, all_entries)
        end
      
        return bundleInfoEntry + ret + bundleLoadedEntry
      end

      protected
    
      # Converts a passed set of requires into entries
      def required_entries(required, entries, requiring_entry, all_entries)
        return [] if required.nil?
        required.map do |filename|
          filename = filename.to_s.downcase.ext('')
          source_filename = "source/#{filename}"
          entry = all_entries.find do |e| 
            e.filename.to_s.downcase.ext('') == source_filename
          end
        
          # try localized version...
          if entry.nil? && !(filename =~ /^lproj\//)
            source_filename = "source/lproj/#{filename}"
            entry = all_entries.find do |e| 
              e.filename.to_s.downcase.ext('') == source_filename
            end
          end
        
          if entry.nil?
            SC.logger.warn "Could not find entry '#{filename}' required in #{requiring_entry.target.target_name.to_s.sub(/^\//,'')}:#{requiring_entry.filename}"
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
      def add_entry_to_set(entry, ret, seen, entries, all_entries)
        return if seen.include?(entry)

        seen << entry
        req = required_entries(entry.required, entries, entry, all_entries)
        req.each do |required|
          next if required.nil?
          add_entry_to_set(required, ret, seen, entries, all_entries)
        end
        ret << entry
      end    
    
    end
  end
end