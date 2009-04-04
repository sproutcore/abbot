# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'task'))

module SC

  # Just like a normal task, but will not run if the destination path already
  # exists and it is newer than the source.
  class Buildfile::BuildTask < ::SC::Buildfile::Task

    def needed?
      return true if DST_PATH.nil? || SRC_PATHS.nil? # just try to build...
      return true if !File.exist?(DST_PATH)
      ret = false
      dst_mtime = File.mtime(DST_PATH)
      SRC_PATHS.each do |path|
        next if path.nil? # skip incase of bad src paths...
        
        timestamp = File.exist?(path) ? File.mtime(path) : EARLY
        ret = ret || (dst_mtime < timestamp)
        break if ret
      end
      return ret 
    end
    
  end
end
  