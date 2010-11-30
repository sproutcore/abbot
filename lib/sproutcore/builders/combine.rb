# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

#require 'pathname'
require 'bundler/setup'
require 'chance'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::Combine < Builder::Base

    # override this method in subclasses to actually do build
    def self.buildWithChance(entry, dst_path)
      new(entry).buildWithChance(dst_path)
    end
      
    def buildWithChance(dst_path)
      theme_name = entry.target.config[:theme]
      chance = Chance::Instance.new({:theme => theme_name })

      entries = entry.ordered_entries || entry.source_entries
  
      entries.each do |entry|
        src_path = entry.stage!.source_path
        next unless File.exist?(src_path)

        chance.map_file(entry.filename, src_path)
      end

      chance.update

      if chance.css
        css = chance.css
        css = rewrite_inline_code(css)
        writeline dst_path, css
      end
    end
    
    # Rewrites any inline content such as static urls.  Subclasseses can
    # override this to rewrite any other inline content.
    #
    # The default will rewrite calls to static_url().
    def rewrite_inline_code(code)
      # look for sc_require, require or sc_resource.  wrap in comment
      code.gsub!(/((sc_require|require|sc_resource)\(\s*['"].*["']\s*\)\s*\;)/, '/* \1 */')
      replace_static_url(code)
      code
    end
    
    def static_url(url=''); "url('#{url}')" ; end
    

    def build(dst_path)
      lines = []
      entries = entry[:ordered_entries] || entry[:source_entries]

      target_name = entry.target[:target_name].to_s.sub(/^\//,'')
      if entry[:top_level_lazy_instantiation] && entry[:combined]
        lines << ";
if ((typeof SC !== 'undefined') && SC && !SC.LAZY_INSTANTIATION) {
  SC.LAZY_INSTANTIATION = {};
}
if(!SC.LAZY_INSTANTIATION['#{target_name}']) {
  SC.LAZY_INSTANTIATION['#{target_name}'] = [];
}
SC.LAZY_INSTANTIATION['#{target_name}'].push(
  (
    function() {
"
      end

      entries.each do |entry|
        src_path = entry.stage![:staging_path]
        next unless File.exist?(src_path)

        lines << "/* >>>>>>>>>> BEGIN #{entry[:filename]} */\n"
        lines += readlines(src_path)
        lines << "\n"
      end

      if entry[:top_level_lazy_instantiation] && entry[:combined]
        lines << "
    }
  )
);
"
      end

      writelines dst_path, lines
    end

  end

end
