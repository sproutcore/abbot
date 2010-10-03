# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This build is used to process a single javascript file.  It will
  # substitute any calls to sc_super and sc_static() (or static_url()).  It
  # does NOT product a combined JavaScript for production.  See the
  # Builder::CombinedJavaScript for more.
  class Builder::JavaScript < Builder::Base

    def readlines(src_path)
      if File.exist?(src_path) && !File.directory?(src_path)
        File.read(src_path)
      else
        ""
      end
    end

    def build(dst_path)
      input_js = readlines(entry[:source_path])
      lines = build_lines(input_js)

      writelines dst_path, lines
    end

    def build_lines(input_js)
      lines = ""
      target_name = entry.target[:target_name].to_s.sub(/^\//,'')

      if entry[:lazy_instantiation] && entry[:notify_onload]
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

      lines << rewrite_inline_code(input_js)

      # Try to load dependencies if we're not combining javascript.
      if entry[:notify_onload]
        lines << "; if ((typeof SC !== 'undefined') && SC && SC.Module && SC.Module.scriptDidLoad) SC.Module.scriptDidLoad('#{target_name}');"
      end

      if entry[:lazy_instantiation] && entry[:notify_onload]
        lines << "
    }
  )
);
"
      end

     lines 
    end

    # Returns true if the current entry is a localized strings file.  These
    # files receive some specialized processing to allow for server-side only
    # strings.  -- You can name a string key beginning with "@@" and it will
    # be removed.
    def localized_strings?
      @lstrings ||= entry[:localized] && entry[:filename] =~ /strings.js$/
    end

    # Rewrites inline content for a single line
    def rewrite_inline_code(code)

      # Fors strings file, remove server-side keys (i.e '@@foo' = 'bar')
      if localized_strings?
        code.gsub!(/["']@@.*["']\s*?:\s*?["'].*["']\s*,\s*$/,'')

      # Otherwise process sc_super
      else
        code.gsub!(/sc_super\(\s*\)/, 'arguments.callee.base.apply(this,arguments)')
        code.gsub!(/sc_super\((.+?)\)/) do
          SC.logger.warn "\nWARNING: Calling sc_super() with arguments is DEPRECATED. Please use sc_super() only.\n\n"
          "arguments.callee.base.apply(this, #{$1})"
        end
      end

      # and finally rewrite static_url
      replace_static_url(code)
      code
    end

  end

end
