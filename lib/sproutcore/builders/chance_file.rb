require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::ChanceFile < Builder::Base

    def build(dst_path)
      entries = entry[:chance_entries] || [entry[:chance_entry]]
      entries.each {|entry| entry.build! }

      chance_file = entry[:chance_file]

      src = entries.map {|entry|
        chance = entry[:chance]

        src = ""
        src = chance.files[chance_file] unless chance.nil?
        src = "" if src.nil?

        src = rewrite_inline_code(src) if chance_file.end_with?("css")

        src
      }.join("\n")

      writeline dst_path, src
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

  end

end


