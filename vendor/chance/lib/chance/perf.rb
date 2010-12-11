require 'stringio'

# Extension to boost performance of ChunkyPNG
module ChunkyPNG
  class Canvas
    def crop(x, y, crop_width, crop_height)
      raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_width + x > width
      raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_height + y > height
      
      new_pixels = Array.new(crop_width * crop_height)
      for cy in 0...crop_height do
        new_pixels[cy*crop_width, crop_width] = pixels.slice((cy + y) * width + x, crop_width)
      end
      ChunkyPNG::Canvas.new(crop_width, crop_height, new_pixels)
    end
  end
end
