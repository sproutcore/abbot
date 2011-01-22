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

    def postprocess_css(src, slices)
      src.gsub (/_sc_chance\:\s*["'](.*)["']\s*;/) {|match|
        slice = slices[$1]

        output = 'background: url("data:image/png;base64,'

        base64Image = Base64.encode64(slice[:image].to_blob(:fast_rgba)).gsub("\n", "")
        output += base64Image

        output += '");'
      }
    end

    def postprocess_css_2x(src, slices)
      src.gsub (/_sc_chance\:\s*["'](.*)["']\s*;/) {|match|
        slice = slices[$1]

        output = 'background: url("data:image/png;base64,'

        base64Image = Base64.encode64(slice[:image].to_blob(:fast_rgba)).gsub("\n", "")
        output += base64Image

        output += '");'

        output += "\n-webkit-background-size: " + slice[:target_width].to_s + "px "
        output += slice[:target_height].to_s + "px;"
      }
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
