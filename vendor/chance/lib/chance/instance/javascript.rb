module Chance
  class Instance
    module JavaScript
      def javascript(opts)
        # Currently, we only include the preload JavaScript
        preload_javascript(opts)
      end

      # Generates the preload JavaScript
      def preload_javascript(opts)
        output = "if (typeof CHANCE_SLICES === 'undefined') var CHANCE_SLICES = [];"
        output += "CHANCE_SLICES = CHANCE_SLICES.concat(["
        output += @slices.map {|name, slice| "'" + slice[:css_name] + "'" }.join(",\n")
        output += "]);"
      end

    end
  end
end
