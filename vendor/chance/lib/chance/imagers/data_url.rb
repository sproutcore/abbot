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
        
        base64Image = Base64.encode64(slice[:image].to_blob(:fast_rgba))
        
        output += base64Image

        output += '"'
        output += ");"
        output += "} \n"
      end

      return output
    end
    

    def preload_javascript
      slices = @slices

      output = "if (typeof CHANCE_SLICES === 'undefined') var CHANCE_SLICES = [];"
      output += "CHANCE_SLICES = CHANCE_SLICES.concat(["
      output += slices.map {|name, slice| "'" + slice[:css_name] + "'" }.join(",\n")
      output += "]);"
    end
  end

end
