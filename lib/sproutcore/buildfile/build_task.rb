require File.expand_path(File.join(File.dirname(__FILE__), 'task'))

module SC

  # Just like a normal task, but will not run if the destination path already
  # exists and it is newer than the source.
  class Buildfile::BuildTask < ::SC::Buildfile::Task

    def needed?
      ret = false
      dst_mtime = File.exist?(DST_PATH) ? File.mtime(DST_PATH) : Rake::EARLY
      SRC_PATHS.each do |path|
        timestamp = File.exist?(path) ? File.mtime(path) : Rake::EARLY
        ret = ret || (dst_mtime < timestamp)
        break if ret
      end
      return ret 
    end
    
  end
end
  