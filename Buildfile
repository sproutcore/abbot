# Abbot Default Buildfile
#
# This build file is loaded when you try to create a library.  It will process
# any config information you include as well as any tasks or other options you
# might define.


##################################################
## FILTERS
##
## Filters are used to build a manifest of files that need to be built.  The
## default filter invoked by the build tool is manifest:prepare.  You can hook
## into the system by adding filters that come before or after.  If you 
## define a filter more than once, your new settings will merge into the old
## ones.

namespace :manifest do

  filter :default # nothing to do here

  desc "Creates a copy_file manifest entry for every file in the bundle"
  filter :catalog do
    source_path = MANIFEST.bundle.source_path
    Dir.glob(File.join(source_path, '**')).each do |path|
      MANIFEST.add_entry :source_path => path.gsub(source_path, '')
    end
  end
  filter :default => :catalog

  desc "Assign a language to each entry in the catalog based on the lproj.  Also make the filename language independent."
  filter :assign_language => :catalog do
    MANIFEST.entries.each do |entry|
      next if entry.source_path.nil?

      lang = entry.source_path.match(/(.+)\.lproj\/?/).to_a.last
      next if lang.nil?
      
      entry.language = lang.to_sym
    end
  end
  filter :default => :assign_language

  desc "Strip any resources not part of the current language"
  filter :localize => :assign_language do
    clang = CONFIG.current_language
    dlang = CONFIG.default_language

    entries = {}
    MANIFEST.entries.each do |entry|
    end
  end
  filter :default => :localize
  config :all, :default_language => :en
  
end
  
namespace :build

  desc "Copy a file from the source path to the destination."
  builder :copy do
    File.cp_r(SRC_PATH, DST_PATH) unless SRC_PATH == DST_PATH
  end

end


