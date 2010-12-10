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
        output += '"data:image/png;base64,'
        
        base64Image = Base64.encode64(slice[:image].to_blob({ :fast_rgba => true }))
        output += base64Image

        output += '"'
        output += ");"
        output += "} \n"
      end

      return output
    end
    
  end

end
