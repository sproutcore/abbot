# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.
namespace :build do

  # copies the files
  build_task :copy do
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(DST_PATH))
    FileUtils.cp_r(SRC_PATH, DST_PATH)
  end
  
end