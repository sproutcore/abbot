# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::Combine < Builder::Base

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
