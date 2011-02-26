require "chance/perf"

module Chance
  class Instance
    
    # The Slicing module handles taking a collection of slice definitions to
    # produce sliced images. It uses ChunkyPNG to perform the slicing, and
    # stores the sliced image in the slice definition.
    module Slicing
      # performs the slicing indicated by each slice definition, and puts the resulting
      # image in the slice definition's :image property.
      #
      # if x2 is supplied, this will assume it is a second pass to locate any @2x images
      # and use them to replace the originals.
      def slice_images(opts)
        slices = @slices
        output = ""

        slices.each do |name, slice|
          # If we modify the canvas, we'll place the modified canvas here.
          # Otherwise, consumers will use slice[:file] [:canvas] or [:contents]
          # to get the original data as needed.
          slice[:canvas] = nil

          # In any case, if there is one, we need to get the original file and canvas;
          # this process also tells us if the slice is 2x, etc.
          canvas = canvas_for slice, opts

          # Check if a canvas is required
          must_slice = (slice[:left] != 0 or slice[:right] != 0 or slice[:top] != 0 or slice[:bottom] != 0)
          if must_slice or slice[:x2]
            if canvas.nil?
              throw "Chance could not load file '#{slice[:path]}'." +
                    "If it is not a PNG, RMagick is required to slice or use @2x mode."
            end

            f = slice[:proportion]

            # RMagick or ChunkyPNG? 'columns' is RMagick
            if canvas.respond_to?('columns')
              canvas_width = canvas.columns
              canvas_height = canvas.rows
            else
              canvas_width = canvas.width
              canvas_height = canvas.height
            end

            if must_slice
              rect = nil
              rect = slice_rect(slice, canvas_width, canvas_height)

              if not rect.nil?
                slice[:canvas] = canvas.crop(rect[:left] * f, rect[:top] * f, rect[:width] * f, rect[:height] * f)
                canvas_width = rect[:height] * f
                canvas_height = rect[:width] * f
              end
            end

            slice[:target_width] = canvas_width / f
            slice[:target_height] = canvas_height / f
          end

        end
      end

      # Returns either a RMagick image or a ChunkyPNG canvas for a slice, as applicable.
      # If not applicable, the :raw property on the passed slice will be set.
      #
      # Opts specify if x2, etc. is allowed.
      def canvas_for(slice, opts)
        file = file_for(slice, opts)
        file[:canvas]
      end

      # Returns the file to use for the specified slice (might be either the
      # normal one, or a @2x one)
      #
      # The slice's :file property will be set to the Chance file.
      # If @2x, the :x2 flag on the slice is set to true.
      # opts specify if x2, etc. is allowed.
      def file_for(slice, opts)
        path = slice[:path]

        file = get_file(path)
        slice[:x2] = false
        slice[:proportion] = 1

        # Check for x2 version if we are in x2 mode
        if opts[:x2]
          begin
            path_2x = path[0..(-1 - File.extname(path).length)] + "@2x.png"

            file = get_file(path_2x)
            slice[:x2] = true
            slice[:proportion] = 2
          rescue
          end
        end

        raise "File does not exist: " + slice[:path] unless file

        slice[:file] = file
        file
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
