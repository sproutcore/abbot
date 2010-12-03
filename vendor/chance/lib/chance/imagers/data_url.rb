require 'chance/imager'
require "base64"

module ChunkyPNG
  class Canvas
    def crop(x, y, crop_width, crop_height)
      raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_width + x > width
      raise ChunkyPNG::OutOfBounds, "Image width is too small!" if crop_height + y > height
      
      new_pixels = Array.new(crop_width * crop_height)
      for cy in 0...crop_height do
        new_pixels[(cy+y)*crop_width, crop_width] = pixels.slice((cy + y) * width + x, crop_width)
      end
      ChunkyPNG::Canvas.new(crop_width, crop_height, new_pixels)
    end
  end
end

module Chance

  class DataURLImager < Chance::Imager

    # Creates the final slice rectangle from the image width and height
    # returns nil if no rectangle
    def slice_rect(slice, image_width, image_height)
      left = slice[:left]
      top = slice[:top]
      bottom = slice[:bottom]
      right = slice[:right]
      width = slice[:width]
      height = slice[:height]

      rect = {}

      if not left.nil?
        rect[:left] = left

        # in this case, it must be left+width or left+right, or left-to-end
        if not right.nil?
          rect[:width] = image_width - right - left
        elsif not width.nil?
          rect[:width] = width
        else
          # then this is left-to-end
          rect[:width] = image_width - left
        end
      elsif not right.nil?
        # in this case it must be right+width or right-to-end
        if not width.nil?
          rect[:left] = image_width - width - right
          rect[:width] = width
        else
          rect[:left] = image_width - right
          rect[:width] = right
        end
      else
        rect[:left] = 0
        rect[:width] = image_width
      end

      if not top.nil?
        rect[:top] = top

        # in this case, it must be top+height or top+bottom or top-to-bottom
        if not bottom.nil?
          rect[:height] = image_height - bottom - top
        elsif not height.nil?
          rect[:height] = height
        else
          rect[:height] = image_height - top
        end
      elsif not bottom.nil?
        # in this case it must be bottom+height
        if not height.nil?
          rect[:top] = image_height - bottom - top
          rect[:height] = height
        else
          rect[:top] = image_height - bottom
          rect[:height] = bottom
        end
      else
        rect[:top] = 0
        rect[:height] = image_height
      end

      return rect
    end

    def css
      output = ""
      slices = @slices

      slices.each do |name, slice|
        # so, the path should be the path in the chance instance
        # puts name + ", " + slice[:path]
        output += "." + slice[:css_name] + " { "
        output += "background-image: url("
        output += '"data:image/png;base64,'

        file = @instance.get_file(slice[:path])
        raise "File does not exist: " + slice[:path] unless file

        # we should have already loaded a chunkypng canvas for the png
        # NOTE: we may replace the way we load that canvas at some point.
        canvas = file[:content]

        rect = slice_rect(slice, canvas.width, canvas.height)

        # but, if we are slicing...
        if not rect.nil?
          canvas = canvas.crop(rect[:left], rect[:top], rect[:width], rect[:height])
        end

        # So now, if we are actually slicing, we nee
        base64Image = Base64.encode64(canvas.to_blob({ :fast_rgba => true }))
        output += base64Image

        output += '"'
        output += ");"
        output += "} \n"
      end

      return output
    end
  end

end
