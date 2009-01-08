
require 'fileutils'

namespace :build do

  desc "Builds a generic resource.  This will simply copy the resource to the new location, if needed"
  build_task :copy do
    FileUtils.cp_r(SRC_PATH, DST_PATH) if File.exist?(SRC_PATH) 
  end
    
end
