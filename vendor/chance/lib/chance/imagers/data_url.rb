require 'chance/imager'
require "base64"

module Chance

  # The DataURL Imager creates CSS with data urls for each slice.
  class DataURLImager < Chance::Imager

    # Creates CSS for the slices to be provided to SCSS.
    # This CSS is incomplete; it will need postprocessing. This CSS
    # is generated with the set of slice definitions in @slices; the actual
    # slicing operation has not yet taken place. The postprocessing portion
    # receives sliced versions.
    def css
      output = ""
      slices = @slices

      slices.each do |name, slice|
        # so, the path should be the path in the chance instance
        output += "." + slice[:css_name] + " { "
        output += "_sc_chance: \"#{name}\";"
        output += "} \n"
      end

      return output

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

    def postprocess_css(src, slices)
      src.gsub (/_sc_chance\:\s*["'](.*)["']\s*;/) {|match|
        slice = slices[$1]

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


        # FOR IE < 8:
        output += '*background-image: url("mhtml:chance-mhtml.txt!' + slice[:css_name] + '");'
        output += "\n"

        output
      }
    end

    def preload_javascript
      slices = @slices

      output = "if (typeof CHANCE_SLICES === 'undefined') var CHANCE_SLICES = [];"
      output += "CHANCE_SLICES = CHANCE_SLICES.concat(["
      output += slices.map {|name, slice| "'" + slice[:css_name] + "'" }.join(",\n")
      output += "]);"
    end

    def mhtml(slices)
      output = "Content-Type: multipart/related; boundary=\"CHANCE__\"\r\n"

      slices.each {|name, slice|
        output += "\r\n--CHANCE__\r\n"
        output += "Content-Location:" + slice[:css_name] + "\r\n"
        output += "Content-Type:image/png\r\n"
        output += "Content-Transfer-Encoding:base64\r\n\r\n"

        base64Image = base64_for(slice)
        output += base64Image.gsub("[^\r]\n", "\r\n")

        output
      }

       output += "\r\n--CHANCE__--"

      output
    end
  end

end
