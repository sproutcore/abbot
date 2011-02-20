#
# This builds CSS representing the sprited images. The sprites should have
# already been generated.
#
module Chance
  # The Sprite Imager creates CSS with background images and positions
  # for sprites containing the slices.
  #
  # The sprites should already be generated. The URLs for the sprites,
  # and their offsets, should be present in 
  class SpriteImager < Chance::Imager
    def css
      output = ""
      slices = @slices

    end


    def postprocess_css(src, slices)
      spriter = Chance::Spriter.new (slices)
      spriter.sprite()

      # Update CSS for each sprite
      
    end
  end
end

