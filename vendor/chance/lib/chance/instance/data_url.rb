require 'base64'

module Chance
  class Instance

    module DataURL

      def postprocess_css_dataurl(opts)
        css = @css.gsub(/_sc_chance\:\s*["'](.*?)["']\s*/) {|match|
          slice = @slices[$1]

          url = 'data:' + type_for(slice[:path]) + ";base64,"
          url += base64_for(slice).gsub("\n", "")

          output = "background-image: url(\"#{url}\");"

          output += "\n"

          # FOR 2X SLICES
          if slice[:x2]
            width = slice[:target_width]
            height = slice[:target_height]
            output += "\n-webkit-background-size: #{width}px #{height}px;"
          end

          output
        }

        # We do not modify the offset, so we can just pass the original through.
        css.gsub!(/-chance-offset:\s?"(.*?)" (-?[0-9]+) (-?[0-9]+)/) {|match|
          "background-position: #{$2}px #{$3}px"
        }

        css
      end

      def type_for(path)
        (path =~ /jpg$/) ? "image/jpeg" : "image/" + path.slice(/(gif|jpeg|png)$/)
      end

      def base64_for(slice)
        if not slice[:canvas].nil?
          # If the slice has a canvas, we must read from that.
          contents = slice[:canvas].to_blob
        else
          # Otherwise, this implies the image has not been modified. So, we should
          # be able to write out the original contents from the slice's file.
          contents = slice[:file][:content]
        end

        Base64.encode64(contents)
      end
    end

  end
end
