# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This builder is used to process a single CSS stylesheet.  Converts any
  # build tool directives (such as sc_require() and sc_resource()) into
  # comments.  It will also substitute any calls to sc_static() (or
  # static_url())  This builder does NOT handle combining multiple stylesheets
  # into one.  See the Builder::CombineStylesheets builder instead.
  #
  class Builder::Stylesheet < Builder::Base

    def build(dst_path)
      code = rewrite_inline_code(read(entry[:source_path]))
      writelines dst_path, code
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

    def sc_static_match
      /(sc_static|static_url|sc_target)\(\s*['"]([^?#"']*)\??(#?[^"']*?)['"]\s*\)/
    end

    # Handles occurances of sc_static() or static_url()
    def replace_static_url(line)
      line.gsub!(sc_static_match) do | rsrc |
        entry_name = $2
        entry_hash = $3 || ''
        entry_name = "#{$2}:index.html" if $1 == 'sc_target'

        static_entry = entry.manifest.find_entry($2)

        if !static_entry
          SC.logger.warn "#{$2} was not found. Line: #{rsrc}"
          url = ''
        elsif $1 == 'sc_target'
          url = static_entry[:friendly_url] || static_entry.cacheable_url
        else
          url = static_entry.cacheable_url + $3
        end

        static_url(url)
      end
    end

  end

end
