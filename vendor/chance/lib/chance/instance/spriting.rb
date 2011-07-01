# Spriting support.
#
# The sprite method performs the spriting. It creates collections of
# images to sprite and then calls layout_sprite and generate_sprite.
#
# The layout_sprite method arranges the slices, defining their positions
# within the sprites.
#
# The generate_sprite method combines the slices into an image.
module Chance

  class Instance

    # The Spriting module handles sorting slices into sprites, laying them
    # out within the sprites, and generating the final sprite images.
    module Spriting
      # Performs the spriting process on all of the @slices, creating sprite
      # images in the class's @sprites property and updating the individual slices 
      # with a :sprite property containing the identifier of the sprite, and offset
      # properties for the offsets within the image.
      def generate_sprite_definitions(opts)        
        @sprites = {}

        group_slices_into_sprites(opts)
        @sprites.each do |key, sprite|
          layout_slices_in_sprite sprite
        end
      end

      # Determines the appropriate sprite for each slice, creating it if necessary,
      # and puts the slice into that sprite. The appropriate sprite may differ based
      # on the slice's repeat settings, for instance.
      def group_slices_into_sprites(opts)
        @slices.each do |key, slice|
          sprite = sprite_for_slice(slice, opts)
          sprite[:slices] << slice

          @sprites[sprite[:name]] = sprite
        end
      end

      # Returns the sprite to use for the given slice, creating the sprite if needed.
      # The sprite could differ based on repeat settings or file type, for instance.
      def sprite_for_slice(slice, opts)
        sprite_name = sprite_name_for_slice(slice, opts)

        get_sprite_named(sprite_name, opts.merge({
          :horizontal_layout => slice[:repeat] == "repeat-y" ? true : false
        }))

        return @sprites[sprite_name]
      end

      # Creates a sprite definition with a given name and set of options
      def get_sprite_named(sprite_name, opts)
        if @sprites[sprite_name].nil?
          @sprites[sprite_name] = {
            :name => sprite_name,
            :slices => [],
            :has_generated => false,

            # The sprite will use horizontal layout under repeat-y, where images
            # must stretch all the way from the top to the bottom
            :use_horizontal_layout => opts[:horizontal_layout]

          }
        end
      end

      # Determines the name of the sprite for the given slice. The sprite
      # by this name may not exist yet.
      def sprite_name_for_slice(slice, opts)
        if slice[:repeat] == "repeat-both"
          return slice[:path] + (opts[:x2] ? "@2x" : "")
        end

        return slice[:repeat] + (opts[:x2] ? "@2x" : "") + File.extname(slice[:path])
      end

      # Performs the layout operation, laying either up-to-down, or "
      # (for repeat-y slices) left-to-right.
      def layout_slices_in_sprite(sprite)
        # The position is the position in the layout direction. In vertical mode
        # (the usual) it is the Y position.
        pos = 0

        # The size is the current size of the sprite in the non-layout direction;
        # for example, in the usual, vertical mode, the size is the width.
        #
        # Usually, this is computed as a simple max of itself and the width of any
        # given slice. However, when repeating, the least common multiple is used,
        # and the smallest item is stored as well.
        size = 1
        smallest_size = nil

        is_horizontal = sprite[:use_horizontal_layout]

        sprite[:slices].each do |slice|
          # We must find a canvas either on the slice (if it was actually sliced),
          # or on the slice's file. Otherwise, we're in big shit.
          canvas = slice[:canvas] || slice[:file][:canvas]

          # TODO: MAKE A BETTER ERROR.
          unless canvas
            throw "Could not sprite image " + slice[:path] + "; if it is not a PNG"
          end

          # RMagick has a different API than ChunkyPNG; we have to detect
          # which one we are using, and use the correct API accordingly.
          if canvas.respond_to?('columns')
            slice_width = canvas.columns
            slice_height = canvas.rows
          else
            slice_width = canvas.width
            slice_height = canvas.height
          end

          slice_length = is_horizontal ? slice_width : slice_height
          slice_size = is_horizontal ? slice_height : slice_width

          # When repeating, we must use the least common multiple so that
          # we can ensure the repeat pattern works even with multiple repeat
          # sizes. However, we should take into account how much extra we are
          # adding by tracking the smallest size item as well.
          if slice[:repeat] != "no-repeat"
            smallest_size = slice_size if smallest_size.nil?
            smallest_size = [slice_size, smallest_size].min

            size = size.lcm slice_size
          else
            size = [size, slice_size].max
          end

          # We have extras for manual tweaking of offsetx/y. We have to make sure there
          # is padding for this (on either side)
          #
          # We have to add room for the minimum offset by adding to the end, and add
          # room for the max by adding to the front. We only care about it in our
          # layout direction. Otherwise, the slices are flush to the edge, so it won't
          # matter.
          if slice[:min_offset_x] < 0 and is_horizontal
            slice_length -= slice[:min_offset_x]
          elsif slice[:min_offset_y] < 0 and not is_horizontal
            slice_length -= slice[:min_offset_y]
          end

          if slice[:max_offset_x] > 0 and is_horizontal
            pos += slice[:max_offset_x]
          elsif slice[:max_offset_y] > 0 and not is_horizontal
            pos += slice[:max_offset_y]
          end


          slice[:sprite_slice_x] = is_horizontal ? pos : 0
          slice[:sprite_slice_y] = is_horizontal ? 0 : pos
          slice[:sprite_slice_width] = slice_width
          slice[:sprite_slice_height] = slice_height

          pos += slice_length
        end

        # TODO: USE A CONSTANT FOR THIS WARNING
        smallest_size = size if smallest_size == nil
        if size - smallest_size > 10
          puts "WARNING: Used more than 10 extra rows or columns to accommodate repeating slices."
          puts "Wasted up to " + (pos * size-smallest_size).to_s + " pixels"
        end

        sprite[:width] = is_horizontal ? pos : size
        sprite[:height] = is_horizontal ? size : pos

      end


      # Generates the image for the specified sprite, putting it in the sprite's 
      # :image property.
      def generate_sprite(sprite)
        canvas = canvas_for_sprite(sprite)
        sprite[:canvas] = canvas

        sprite[:slices].each do |slice|
          x = slice[:sprite_slice_x]
          y = slice[:sprite_slice_y]
          width = slice[:sprite_slice_width]
          height = slice[:sprite_slice_height]

          # If it repeats, it needs to go edge-to-edge in one direction
          if slice[:repeat] == 'repeat-y'
            height = sprite[:height]
          end

          if slice[:repeat] == 'repeat-x'
            width = sprite[:width]
          end

          compose_slice_on_canvas(canvas, slice, x, y, width, height)
        end
      end

      def canvas_for_sprite(sprite)
        width = sprite[:width]
        height = sprite[:height]

        # If we require RMagick, we should have already loaded it, so we don't
        # need to worry over that at the moment.
        if sprite[:name] =~ /\.(gif|jpg)/
          return Magick::Image.new(width, height)
        else
          return ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
        end
      end

      # Writes a slice to the target canvas, repeating it as necessary to fill the width/height.
      def compose_slice_on_canvas(target, slice, x, y, width, height)
        source_canvas = slice[:canvas] || slice[:file][:canvas]
        source_width = slice[:sprite_slice_width]
        source_height = slice[:sprite_slice_height]

        top = 0
        left = 0

        # Repeat the pattern to fill the width/height.
        while top < height do
          left = 0

          while left < width do
            if target.respond_to?(:replace!)
              target.replace!(source_canvas, left + x, top + y)
            else
              target.composite!(source_canvas, left + x, top + y)
            end

            left += source_width
          end

          top += source_height
        end

      end

      # Postprocesses the CSS, inserting sprites and defining offsets.
      def postprocess_css_sprited(opts)
        # The images should already be sliced appropriately, as we are
        # called by the css method, which calls slice_images.

        # We will need the position of all sprites, so generate the sprite
        # definitions now:
        generate_sprite_definitions(opts)

        css = @css.gsub(/_sc_chance:\s*["'](.*?)["']/) {|match|
          slice = @slices[$1]
          sprite = sprite_for_slice(slice, opts)

          output = "background-image: chance_file('#{sprite[:name]}')\n"

          if slice[:x2]
            width = sprite[:width] / slice[:proportion]
            height = sprite[:height] / slice[:proportion]
            output += ";  -webkit-background-size: #{width}px #{height}px"
          end

          output
        }

        css.gsub!(/-chance-offset:\s?"(.*?)" (-?[0-9]+) (-?[0-9]+)/) {|match|
          slice = @slices[$1]

          slice_x = $2.to_i - slice[:sprite_slice_x]
          slice_y = $3.to_i - slice[:sprite_slice_y]

          # If it is 2x, we are scaling the slice down by 2, making all of our
          # positions need to be 1/2 of what they were.
          if slice[:x2]
            slice_x /= slice[:proportion]
            slice_y /= slice[:proportion]
          end

          "background-position: #{slice_x}px #{slice_y}px"
        }

        css

      end

      def sprite_data(opts)
        _render
        slice_images(opts)
        generate_sprite_definitions(opts)

        sprite = @sprites[opts[:name]]

        # When the sprite is nil, it simply means there weren't any images,
        # so this sprite is not needed. But build systems may still
        # expect this file to exist. We'll just make it empty.
        if sprite.nil?
          return ""
        end


        generate_sprite(sprite) if not sprite[:has_generated]

        ret = sprite[:canvas].to_blob
        
        if Chance.clear_files_immediately
          sprite[:canvas] = nil
          sprite[:has_generated] = false
        end
        
        ret
      end

      def sprite_names(opts={})
        _render
        slice_images(opts)
        generate_sprite_definitions(opts)

        @sprites.keys
      end

    end
  end
end
