# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2010 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'fileutils'

module SC

  # This builder create an HTML5 manifest file for application caching
  #
  class Builder::HTML5Manifest < Builder::Base
    
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
      
      manifest_path = dst_path.sub('index.html', '') + 'app.manifest'
      writelines manifest_path, @files
      puts manifest_path
    end
    
    def joinlines(lines)
      lines.join("\n")
    end
    
    def inspect_files(base_path, dst_path)
      path = base_path + dst_path
      content = readlines(path)
      
      content.each do |line|
        line.scan(/['"]([^\s]+?(?=\.(css|js|png|gif))\.\2)['"]/) do |x, y, z|
          file_location = x
          # in case of hyperdomaining, strip off the http part and then look
          # for the file
          if x[0,4] == 'http'
            file_location = '/' + x.gsub(/http\:\/\/.*?\//, '')
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
      
      @files
      
    end
    
  end
  
end
