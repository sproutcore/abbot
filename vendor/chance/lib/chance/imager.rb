module Chance
  class Imager
    attr_reader :css
    def initialize(slices, instance)
      @slices = slices
      @instance = instance
    end

    def css
      ""
    end

    def preload_javascript
      ""
    end

    def mhtml(slices)
      ""
    end
  end
end
