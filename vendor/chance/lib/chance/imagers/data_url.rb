require 'chance/imager'
require "base64"


module Chance

  # The DataURL Imager creates CSS with data urls for each slice.
  class DataURLImager < Chance::Imager

    def css
      output = ""
      slices = @slices

      slices.each do |name, slice|
        # so, the path should be the path in the chance instance
        output += "." + slice[:css_name] + " { "
        output += "background: url("

        # set the mime type from the extension (while taking care of .jpg extensions)
        mimeType = (slice[:path] =~ /jpg$/) ? "image/jpeg" : "image/" + slice[:path].slice(/(gif|jpeg|png)$/)

        output += '"data:' + mimeType
        output += ';base64,'

        # ChunkyPNG & RMagick images respond to to_blob, other images will be encoded from their contents
        if (slice[:image].respond_to? "to_blob")
          method = slice[:image].method(:to_blob)

          # ChunkyPNG takes an argument to to_blob
          slice[:image] = (method.arity == 1) ? slice[:image].to_blob(:fast_rgba) : slice[:image].to_blob
        end

        base64Image = Base64.encode64(slice[:image])

        output += base64Image

        output += '"'
        output += ");"
        output += "} \n"
      end

      return output
    end

  end

end
