require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::Chance < Builder::Base

    def build(dst_path)

      theme_name = entry.target.config[:css_theme]

      chance = Chance::Instance.new({:theme => theme_name })

      entries = entry.ordered_entries || entry.source_entries

      entries.each do |entry|
        src_path = entry[:source_path]
        next unless File.exist?(src_path)

        Chance.add_file src_path
        chance.map_file(entry.filename, src_path)
      end

      chance.update

      if chance.files["chance.css"]
        css = chance.files["chance.css"]
        css = rewrite_inline_code(css)

        writeline dst_path, css
      end

      entry[:chance] = chance
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
