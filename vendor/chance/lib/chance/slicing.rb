require "chance/perf"

module Chance
  class Instance

    # The Slicing module handles taking a collection of slice definitions to
    # produce sliced images. It uses ChunkyPNG to perform the slicing, and
    # stores the sliced image in the slice definition.
    module Slicing
      # performs the slicing indicated by each slice definition, and puts the resulting
      # image in the slice definition's :image property.
      def slice_images
        slices = @slices
        output = ""

        slices.each do |name, slice|
          file = get_file(slice[:path])
          raise "File does not exist: " + slice[:path] unless file

          if file[:path] =~ /png$/
            # we should have already loaded a chunkypng canvas for the png
            canvas = file[:content]

            rect = slice_rect(slice, canvas.width, canvas.height)

            # but, if we are slicing...
            if not rect.nil?
              canvas = canvas.crop(rect[:left], rect[:top], rect[:width], rect[:height])
            end

            slice[:image] = canvas
          else
            # Warn if there are any slice directives on an un-sliceable image
            if slice[:left] != 0 or slice[:right] != 0 or slice[:top] != 0 or slice[:bottom] != 0
              SC.logger.warn "Chance only supports slicing of PNG images, the image '#{slice[:filename]}' will be embedded unsliced"
            end

            slice[:image] = file[:content]
          end
        end
      end

      # Creates the final slice rectangle from the image width and height
      # returns nil if no rectangle or if the slice is the full image
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
            rect[:top] = image_height - height - bottom
            rect[:height] = height
          else
            rect[:top] = image_height - bottom
            rect[:height] = bottom
          end
        else
          rect[:top] = 0
          rect[:height] = image_height
        end

        if rect[:left] == 0 and rect[:top] == 0 and rect[:width] == image_width and rect[:height] == image_height
          return nil
        end

        return rect
      end
    end
  end
end
