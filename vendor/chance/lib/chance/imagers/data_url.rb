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

    def base64_image_for(slice)

      # ChunkyPNG & RMagick images respond to to_blob, other images will be encoded from their contents
      if (slice[:image].respond_to? "to_blob")
        method = slice[:image].method(:to_blob)

        # ChunkyPNG takes an argument to to_blob
        slice[:image] = (method.arity == 1) ? slice[:image].to_blob(:fast_rgba) : slice[:image].to_blob
      end

      Base64.encode64(slice[:image]).gsub("\n", "")
    end

    def data_uri_for(slice)
      output = 'background: url('

      # set the mime type from the extension (while taking care of .jpg extensions)
      mimeType = (slice[:path] =~ /jpg$/) ? "image/jpeg" : "image/" + slice[:path].slice(/(gif|jpeg|png)$/)

      output += '"data:' + mimeType
      output += ';base64,'

      base64Image = base64_image_for(slice)

      output += base64Image

      output += '");'
    end

    def postprocess_css(src, slices)
      src.gsub(/_sc_chance\:\s*["'](.*)["']\s*;/) do |match|
        slice = slices[$1]

        output = data_uri_for(slice)

        # FOR IE < 8:
        output += '\n*background: url("mhtml:chance-mhtml.txt!' + slice[:css_name] + '");'
        output += "\n"

        output
      end
    end

    def postprocess_css_2x(src, slices)
      src.gsub(/_sc_chance\:\s*["'](.*)["']\s*;/) do |match|
        slice = slices[$1]

        output = data_uri_for(slice)

        output += "\n-webkit-background-size: " + slice[:target_width].to_s + "px "
        output += slice[:target_height].to_s + "px;\n"

        output
      end
    end

    def preload_javascript
      slices = @slices

      output = "if (typeof CHANCE_SLICES === 'undefined') var CHANCE_SLICES = [];"
      output += "CHANCE_SLICES = CHANCE_SLICES.concat(["
      output += slices.map {|name, slice| "'" + slice[:css_name] + "'" }.join(",\n")
      output += "]);"
    end

    def mhtml(slices)
      output = "Content-Type: multipart/related; boundary=\"CHANCE__BOUNDARY__\"\r\n"

      slices.each {|name, slice|
        output += "\n--CHANCE__BOUNDARY__\r\n"
        output += "Content-Location:" + slice[:css_name] + "\r\n"
        output += "Content-Transfer-Encoding:base64\r\n\r\n"

        base64Image = base64_image_for(slice)

        output += base64Image
        output += "\r\n"

        output
      }

       output += "--CHANCE__BOUNDARY__--"

      output
    end
  end

end
