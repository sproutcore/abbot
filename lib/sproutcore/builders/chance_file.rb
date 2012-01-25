require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::ChanceFile < Builder::Base

    def build(dst_path)
      instances = entry[:chance_instances] || [entry[:chance_instance]]
      
      # Ensure all entries are staged. When Abbot updates, it may skip regenerating
      # the manifest and just run us, in which case, the previous staged version
      # will be out-of-date.
      entry[:source_entries].each {|e| e.stage! if entry[:build_required] }

      chance_file = entry[:chance_file]

      src = instances.map {|chance|
        # Because files were restaged, they could be out-of-date.
        # Let's double-check them all.
        chance.check_all_files


        src = ""
        src = chance.output_for chance_file unless chance.nil?
        src = "" if src.nil?

        if (chance_file.end_with?("css") or chance_file.end_with?("js")) and src.length > 0
          src = rewrite_inline_code(src) if chance_file.end_with?("css")
          src += "\n"
        end

        src
      }.join("")

      # Don't write empty files... but keep in mind that hte 
      if src.length > 0
        if chance_file.end_with?("png")
          # Writing it as binary to avoid newline problems on Windows
          writelinebinary dst_path, src
        else
          writeline dst_path, src
        end
      end
    end

    # Rewrites any inline content such as static urls.  Subclasseses can
    # override this to rewrite any other inline content.
    #
    # The default will rewrite calls to static_url().
    def rewrite_inline_code(code)
      # chance_files refer, usually, to sprites.
      code.gsub!(/chance_file\(["'](.*?)['"]\)/) {|match|
        path = entry[:resource_name] + "-" + $1
        "static_url('#{path}')"
      }

      code.gsub!(/external_file\(["'](.*?)['"]\)/) {|match|
        "static_url('#{$1}')"
      }

      # look for sc_require, require or sc_resource.  wrap in comment
      code.gsub!(/((sc_require|require|sc_resource)\(\s*['"].*["']\s*\)\s*\;)/, '/* \1 */')
      replace_static_url(code)
      code
    end

    def static_url(url=''); "url('#{url}')" ; end


  end

end


