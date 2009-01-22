require File.expand_path(File.join(File.dirname(__FILE__), 'task'))

module SC

  # Just like a normal task, but will not run if the destination path already
  # exists and it is newer than the source.
  class Buildfile::BuildTask < ::SC::Buildfile::Task

    def needed?
      return true if DST_PATH.nil? || SRC_PATHS.nil? # just try to build...
      
      ret = false
      dst_mtime = File.exist?(DST_PATH) ? File.mtime(DST_PATH) : EARLY
      SRC_PATHS.each do |path|
        timestamp = (path && File.exist?(path)) ? File.mtime(path) : EARLY
        ret = ret || (dst_mtime < timestamp)
        break if ret
      end
      return ret 
    end
    
  end
end
  