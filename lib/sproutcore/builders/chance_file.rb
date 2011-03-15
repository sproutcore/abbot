require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::ChanceFile < Builder::Base

    def build(dst_path)
      instances = entry[:chance_instances] || [entry[:chance_instance]]

      chance_file = entry[:chance_file]

      src = instances.map {|chance|

        src = ""
        src = chance.output_for chance_file unless chance.nil?
        src = "" if src.nil?

        src = rewrite_inline_code(src) if chance_file.end_with?("css")

        src
      }.join("\n")

      # Don't write empty files...
      if src.strip.length > 0
        writeline dst_path, src
      end
    end

    # Rewrites any inline content such as static urls.  Subclasseses can
    # override this to rewrite any other inline content.
    #
    # The default will rewrite calls to static_url().
    def rewrite_inline_code(code)
      # look for sc_require, require or sc_resource.  wrap in comment
      code.gsub!(/url\s*\(\s*["']mhtml\:chance-mhtml\.txt!(.+?)["']\s*\)/) {|mhtml|
        static_entry = entry.manifest.find_entry("__sc_chance_mhtml.txt")

        if !static_entry
          url = ''
        else
          url = static_entry.cacheable_url
        end

        "expression('url(\"mhtml:' + document.location.protocol + '//' + document.location.host + '" + url + "!" + $1 + "' + '\")')"
      }

      # chance_files refer, usually, to sprites.
      code.gsub!(/chance_file\(["'](.*?)['"]\)/) {|match|
        path = entry[:resource_name] + "-" + $1
        "static_url('#{path}')"
      }

      code.gsub!(/external_file\(["'](.*?)['"]\)/) {|match|
        "static_url('#{$1}')"
      }

      code.gsub!(/((sc_require|require|sc_resource)\(\s*['"].*["']\s*\)\s*\;)/, '/* \1 */')
      replace_static_url(code)
      code
    end

    def static_url(url=''); "url('#{url}')" ; end


  end

end


