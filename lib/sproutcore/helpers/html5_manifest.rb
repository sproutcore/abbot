# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2010 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================
require 'fileutils'

module SC::Helpers

  # Creates an HTML5 manifest file for application caching
  class HTML5Manifest

    def build(dst_path)
      @files = []

      @files << "CACHE MANIFEST\n# List of all resources required by this project\n"

      path = dst_path.split('/tmp/build')

      inspect_files(path[0] + '/tmp/build', path[1])

      networks = $to_html5_manifest_networks
      if networks
        @files << "\n\nNETWORK:"
        networks.each do |network|
          @files << network
        end
        @files << "\n"
      end

      manifest_path = dst_path.sub('index.html', '') + 'manifest.appcache'
      writelines manifest_path, @files
    end

    # writes the passed lines to the named file
    def writelines(dst_path, lines)
      FileUtils.mkdir_p(File.dirname(dst_path))
      f = File.open(dst_path, 'w')
      f.write joinlines(lines)
      f.close
    end

    def joinlines(lines)
      lines.join("\n")
    end

    # Reads the lines from the source file.  If the source file does not
    # exist, returns empty array.
    def readlines(src_path)
      if File.exist?(src_path) && !File.directory?(src_path)
        File.readlines(src_path)
      else
        []
      end
    end

    def inspect_files(base_path, dst_path)
      path = base_path + dst_path
      content = readlines(path)

      content.each do |line|
        line.scan(/['"]([^\s]+?(?=\.(css|js|png|gif|jpg|jpeg))\.\2)['"]/i) do |x, y, z|
          file_location = x
          # in case of hyperdomaining, strip off the http part and then look
          # for the file
          if x[0,4] == 'http'
            file_location = '/' + x.gsub(/https?\:\/\/.*?\//, '')
          end

          next unless File.exist?(base_path + file_location)

          if !@files.include?(x)
            @files << x
          end

          if y == 'css' || y == 'js'
            inspect_files(base_path, file_location)
          end

        end
      end

    end

  end

end
