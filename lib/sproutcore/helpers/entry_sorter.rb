# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "set"


# Backwards compatibility for Ruby 1.8
class Array
  unless method_defined?(:sort_by!)
    def sort_by!(*args, &block)
      replace(sort_by(*args, &block))
    end
  end
end


module SC

  module Helpers

    # Sorts a set of entries, respecting any "requires" found in the entries.
    # To use the sorter, just call the class method EntrySorter.sort() passing
    # the entries to sort along with any filenames you prefer to have added to
    # the top.  If you don't specify any filenames, then the entries will be
    # sorted alphabetically except for requires.
    #
    # When module_info.js is present, it will always be sorted first.
    class EntrySorter

      def self.sort(entries, preferred_filenames = [])
        self.new(preferred_filenames).sort(entries)
      end

      def initialize(preferred_filenames = [])
        @preferred_filenames = preferred_filenames
      end

      attr_reader :preferred_filenames

      def sort(entries)
        moduleInfoEntry = []
        bundleLoadedEntry = []

        all_entries = {}
        entries.each do |e|
          name = e.extensionless_filename
          all_entries[name] = e
        end


        # first remove bundle entries which MUST be first or last
        entries = entries.select do |entry|
          if entry.normalized_filename == 'module_info.js'
            moduleInfoEntry = [entry]
            false
          else
            true
          end
        end

        entries.sort_by! do |entry|
          name = entry.normalized_filename

          result = case name
          when /main\.js$/
            [2, name]
          when /(?:lproj|resources)\/.+_page\.js$/
            [1, name]
          when /lproj\/strings.js$/
            [-2, name]
          else
            [-1, name]
          end

          # force preferred filenames to the front on the list
          result.unshift(@preferred_filenames.include?(name) ? -1 : 1)
        end

        # now process each entry to handle requires
        seen = Set.new
        ret = []
        while cur = entries.shift
          add_entry_to_set(cur, ret, seen, entries, all_entries)
        end

        return moduleInfoEntry + ret
      end

      protected

      # Converts a passed set of requires into entries
      def required_entries(required, entries, requiring_entry, all_entries)
        return [] unless required

        required.map do |filename|
          normalized_filename = filename.downcase
          entry = all_entries["source/#{normalized_filename}"] || all_entries["source/lproj/#{normalized_filename}"]

          unless entry
            SC.logger.warn "Could not find entry '#{filename}' required in #{requiring_entry.target[:target_name].to_s.sub(/^\//,'')}:#{requiring_entry[:filename]}"
          end

          entry
        end.compact
      end

      # Adds the specified entry to the ordered array, adding required first
      def add_entry_to_set(entry, ret, seen, entries, all_entries)
        return if seen.include?(entry)

        seen << entry
        req = required_entries(entry[:required], entries, entry, all_entries)
        req.each do |required|
          add_entry_to_set(required, ret, seen, entries, all_entries)
        end
        ret << entry
      end

    end
  end
end
