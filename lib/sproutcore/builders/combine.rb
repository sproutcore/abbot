require 'fileutils'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::Combine < Builder
    
    def build(dst_path)
      lines = []
      entries = entry.ordered_entries || entry.source_entries
      entries.each do |entry|
        src_path = entry.stage!.staging_path
        next unless File.exist?(src_path)
        
        lines << "/* >>>>>>>>>> BEGIN #{entry.filename} */\n"
        lines += readlines(src_path)
        lines << "\n"
      end
      writelines dst_path, lines
    end
    
  end
  
end
