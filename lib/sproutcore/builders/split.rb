# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2011 Apple Inc.
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This builder is used to split packed CSS files, ironically enough,
  # into smaller CSS files. This is due to an IE limitation of ~4096 maximum
  # selectors per file.
  #
  # This is a bit hacky, but we add additional manifest entries even though, technically,
  # the manifest generation process is finished. We do this because we have NO WAY
  # of knowing how many selectors there will be until CSS is both built and packed.
  #
  # The static HTML helper makes sure to build! the packed stylesheet entries first so
  # that this rule has been processed. After that, it looks for [:split_entries] on the
  # packed entry.
  class Builder::SplitCSS < Builder::Base
    def build(dst_path)
      e = entry.source_entry
      e.stage!
      
      src = File.read(entry[:staging_path])
      files = SC::Helpers::SplitCSS.split_css src
      
      if files.length > 1 and entry.target.config[:split_css_for_ie]
        entry[:split_entries] = []
        entry[:is_split] = true
        entry.hide!
        
  
        files.each_index {|index|
          name = entry[:filename].sub /\.css$/, ""
          
          path = dst_path.sub /\.css$/, ""
          path = "#{path}-#{index}.css"
      
          writeline path, files[index]
      
          # Is this hacky? Yes. But IE is stupid. So we have to modify the manifest
          # very late, because we don't know the 
          resource_name = "#{name}-#{index}.css"
          split_entry = entry.manifest.add_composite resource_name,
            :staging_path => path,
            :build_path => path,
            :source_entries => [entry],
            :url => [entry.manifest[:url_root], resource_name].join("/"),
            :timestamp => entry[:timestamp]

          entry[:split_entries] << split_entry
        }
      else
        e.build!
      end
    end

  end

end
