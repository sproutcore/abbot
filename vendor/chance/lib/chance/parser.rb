# THE PARSER
#
# The parser will not bother splitting into tokens. We are _a_
# step up from Regular Expressions, not a thousand steps.
#
# In short, we keep track of two things: { } and strings.
#
# Other than that, we look for @theme, slices(), and slice(),
# in their various forms.
#
# Our method is to scan until we hit a delimiter followed by any
# of the following:
#
# - @theme
# - @include slices(
# - slices(
# - slice(
#
# Options
# --------------------------------
# You may pass a few configuration options to a Chance instance:
#
# - :theme: a selector that will make up the initial value of the $theme
#   variable. For example: :theme => "ace.test-controls"
#
# - :compress: if true, the slice names in the CSS will be shortened.
#   This has two drawbacks: 1) the slice names will not be helpful for
#   debugging, and 2) if using Chance in a standalone way and committing
#   the output to a source control system, the output can change dramatically
#   between runs, even if the input CSS is unchanged.
#   
#   As the most common use of Chance is as part of the SC build tools,
#   and this debugging support is usually only required to debug Chance
#   itself, :compress defaults to true
#
# How Slice & Slices work
# -------------------------------
# @include slice() and @include slices() are not actually responsible
# for slicing the image. They do not know the image's with or height.
#
# All that they do is determine the slice's configuration, including
# its file name, the rectangle to slice, etc.
require "json"
require "set"
require "stringio"
require "pathname"

module Chance

  class Parser
    attr_reader :slices, :css
    
    UNTIL_SINGLE_QUOTE = /(?!\\)'/
    UNTIL_DOUBLE_QUOTE = /(?!\\)"/
    
    BEGIN_SCOPE = /\{/
    END_SCOPE = /\}/
    THEME_DIRECTIVE = /@theme\s*/
    SELECTOR_THEME_VARIABLE = /\$theme\./
    INCLUDE_SLICES_DIRECTIVE = /@include\s+slices\s*/
    INCLUDE_SLICE_DIRECTIVE = /@include\s+slice\s*/
    CHANCE_FILE_DIRECTIVE = /@_chance_file /
    NORMAL_SCAN_UNTIL = /[^{}@$]+/

    @@uid = 0

    def initialize(string, opts = {})
      @opts = { :theme => "", :compress => true }
      @opts.merge!(opts)
      @path = ""

      
      @input = string
      @css = ""

      @slices = @opts[:slices]  # we update the slices given to us
      
      @theme = @opts[:theme]
      
      @@uid += 1
      @uid = @@uid

    end

    # SLICE MANAGEMENT
    # -----------------------
    def create_slice(opts)
      filename = opts[:filename]

      # get current relative path
      relative = File.dirname(@path)

      # Create a path
      path = File.join(relative, filename)
      path = path[2..-1] if path[0,2] == "./"
      path = Pathname.new(path).cleanpath.to_s

      opts = opts.merge({ :path => path })
      opts = normalize_rectangle(opts)

      slice_path = path[0..-File.extname(filename).length-1]

      # we add a bit to the path: the slice info
      rect_params = [:left, :top, :width, :height, :bottom, :right, :offset_x, :offset_y]
      
      # Generate string-compatible params
      slice_name_params = rect_params.map {|param|
        ret = ""
        ret = opts[param] if not opts[param].nil?
        ret
      }
      slice_name_params.unshift slice_path

      # validate and convert to integers
      rect_params.each {|param|
        value = opts[param]
        if not value.nil?
          value = Integer(value)
          opts[param] = value
        end
      }



      # it is too expensive to open the images and get their sizes at this point, though
      # I rather would like to.transform the rectangle into absolute coordinates
      # (left top width height) and use that instead of showing all six digits.
      slice_path = "%s_%s_%s_%s_%s_%s_%s" % slice_name_params

      if @slices.has_key?(slice_path)
        slice = @slices[slice_path]
        slice[:min_offset_x] = [slice[:min_offset_x], opts[:offset_x]].min
        slice[:min_offset_y] = [slice[:min_offset_y], opts[:offset_y]].min
        
        slice[:max_offset_x] = [slice[:max_offset_x], opts[:offset_x]].max
        slice[:max_offset_y] = [slice[:max_offset_y], opts[:offset_y]].max
      else
        parts = slice_path.split("/")
        css_name = "__slice_" + parts.join("_")

        if @opts[:compress]
          css_name = "__s" + @uid.to_s + "_" + @slices.length.to_s
        end

        slice = opts.merge({ 
          :name => slice_path, 
          :path => path,
          :css_name => css_name,
          :min_offset_x => opts[:offset_x], # these will be taken into account when spriting.
          :min_offset_y => opts[:offset_y],
          :max_offset_x => opts[:offset_x],
          :max_offset_y => opts[:offset_y],
          :imaged_offset_x => 0, # the imaging process will re-define these.
          :imaged_offset_y => 0
        })

        @slices[slice_path] = slice
      end

      return slice
    end
    
    def normalize_rectangle(rect)
      # try to make the rectangle somewhat standard: that is, make it have
      # all units which make sense
      
      # it must have either a left or a right, no matter what
      rect[:left] = 0 if rect[:left].nil? and rect[:right].nil?
      
      # if there is no width, it must have a both left and right
      if rect[:width].nil?
        rect[:left] = 0 if rect[:left].nil?
        rect[:right] = 0 if rect[:right].nil?
      end
      
      # it must have either a top or a bottom, no matter what
      rect[:top] = 0 if rect[:top].nil? and rect[:bottom].nil?
      
      # if there is no height, it must have _both_ top and bottom
      if rect[:height].nil?
        rect[:top] = 0 if rect[:top].nil?
        rect[:bottom] = 0 if rect[:bottom].nil?
      end
      
      return rect
    end

    # PARSING
    # -----------------------
    def parse
      @scanner = StringScanner.new(@input)

      @image_names = {}
      @css = _parse

      if not @scanner.eos?
        # how do we do an error?
        raise SyntaxError, "Found end of block; expecting end of file."
      end

    end

    # _parse will parse until it finds either the end or until it finds
    # an unmatched ending brace. An unmatched ending brace is assumed
    # to mean that this is a recursive call.
    def _parse
      scanner = @scanner
      
      output = []

      while not scanner.eos? do
        output << handle_empty
        break if scanner.eos?

        if scanner.match?(BEGIN_SCOPE)
          output << handle_scope
          next
        end

        if scanner.match?(THEME_DIRECTIVE)
          output << handle_theme
          next
        end

        if scanner.match?(SELECTOR_THEME_VARIABLE)
          output << handle_theme_variable
          next
        end

        if scanner.match?(INCLUDE_SLICES_DIRECTIVE)
          output << handle_slices
          next
        end

        if scanner.match?(INCLUDE_SLICE_DIRECTIVE)
          output << handle_slice_include
          next
        end
        
        if scanner.match?(CHANCE_FILE_DIRECTIVE)
          handle_file_change
          next
        end

        break if scanner.match?(END_SCOPE)

        # skip over anything that our tokens do not start with
        res = scanner.scan(NORMAL_SCAN_UNTIL)
        if res.nil?
          output << scanner.getch
        else
          output << res
        end
        
      end

      output = output.join
      return output
    end

    def handle_comment
      scanner = @scanner
      scanner.pos += 2
      scanner.scan_until /\*\//
    end

    def parse_string(cssString)
      # I cheat: to parse strings, I use JSON.
      # This will fail with strings quoted with "'", so I'm
      # just not bothering for now. At some point, I should either make 
      # this function more proper or use some other function...
      if not cssString[0..0] == '"'
        return cssString
      end

      return JSON.parse("[" + cssString + "]").first
    end

    def handle_string
      scanner = @scanner

      str = scanner.getch
      str += scanner.scan_until(str == "'" ? UNTIL_SINGLE_QUOTE : UNTIL_DOUBLE_QUOTE)

      return str
    end

    def handle_empty
      scanner = @scanner
      output = ""
      
      while true do
        if scanner.match?(/\s+/)
          output += scanner.scan /\s+/
          next
        end
        if scanner.match?(/\/\*/)
          handle_comment
          next
        end
        break
      end

      return output
    end

    def handle_scope
      scanner = @scanner

      scanner.scan /\{/

      output = '{'
      output += _parse
      output += '}'

      raise SyntaxError, "Expected end of block." unless scanner.scan /\}/

      return output
    end

    def handle_theme
      scanner = @scanner
      scanner.scan THEME_DIRECTIVE

      if scanner.scan(/\((.+?)\)\s*/).nil?
        raise SyntaxError, "Expected (theme-name) after @theme"
      end

      theme_name = scanner[1]

      raise SyntaxError, "Expected { after @theme." unless scanner.scan /\{/

      # calculate new theme name
      old_theme = @theme
      @theme = old_theme + "." + theme_name


      output = ""
      output += "\n$theme: '" + @theme + "';\n"
      output += _parse
      
      @theme = old_theme
      output += "$theme: '" + @theme + "';\n"

      raise SyntaxError, "Expected end of block." unless scanner.scan /\}/

      return output
    end

    def handle_theme_variable
      scanner = @scanner
      scanner.scan SELECTOR_THEME_VARIABLE

      output = "\#{$theme}."

      return output
    end

    # when we receive a @_chance_file directive, it means that our current file
    # scope has changed. We need to know this because we parse the combined file
    # rather than the individual pieces, yet we have paths relative to the original
    # files.
    def handle_file_change
      scanner = @scanner
      scanner.scan CHANCE_FILE_DIRECTIVE
      
      path = scanner.scan_until /;/
      path = path[0..-1]

      @path = path
    end

    def parse_argument
      scanner = @scanner

      # We do not care for whitespace or comments
      handle_empty

      # this is the final value; we won't actually set it until
      # the very end.
      value = nil

      # this holds the value as we are parsing it
      parsing_value = ""

      
      # The key MAY be present if we are starting with a $.
      # But remember: it could be $abc: $abc + $def
      key = :NO_KEY
      if scanner.match?(/\$/)
        scanner.scan /\$/

        handle_empty
        parsing_value = scanner.scan(/[a-zA-Z_-][a-zA-Z0-9+_-]*/)

        raise SyntaxError, "Expected a valid key." if key.nil?

        handle_empty

        if scanner.scan(/:/)
          # ok, it was a key
          key = parsing_value.intern
          parsing_value = ""

          handle_empty
        end
      end

      value = nil
      
      # we stop when we either a) reach the end of the arglist, or
      # b) reach the end of the argument. Argument ends at ',', list ends
      # at ')'
      parsing_value += handle_empty

      until scanner.match?(/[,)]/) or scanner.eos? do
        if scanner.match?(/["']/)
          parsing_value += handle_string
          parsing_value += handle_empty
          next
        end

        parsing_value += scanner.getch

        parsing_value += handle_empty
      end

      value = parsing_value unless parsing_value.empty?

      return { :key => key, :value => value }
    end

    # Parses a list of arguemnts, INCLUDING beginning AND ending
    # parenthesis.
    def parse_argument_list
      scanner = @scanner

      raise SyntaxError, "Expected ( to begin argument list." unless scanner.scan /\(/
      
      idx = 0
      args = {}
      until scanner.match?(/\)/) or scanner.eos? do
        arg = parse_argument
        if arg[:key] == :NO_KEY
          arg[:key] = idx
          idx += 1
        end

        args[arg[:key]] = arg[:value].strip

        scanner.scan /,/
      end

      scanner.scan /\)/

      return args
    end

    def generate_slice_include(slice)
      # the argument list is rather raw. We need to combine it with default values,
      # and preprocess any arguments, before we can call create_slice to get the real
      # slice definition
      slice[:offset] = "0 0" if slice[:offset].nil?
      slice[:repeat] = "no-repeat" if slice[:repeat].nil?

      # the offset will be given to us as one string; however, it has two parts.
      # splitting by whitespace doesn't handle everything, so we may want to refine
      # this at some point unless we could just pass the whole offset to the offset
      # function somehow.
      offset = slice[:offset].strip.split(/\s+/)
      slice[:offset_x] = offset[0]
      slice[:offset_y] = offset[1]

      slice = create_slice(slice)


      output = ""
      output += "@extend ." + slice[:css_name] + ";\n"
      output += "background-position: "
      output += "_slice_offset_x(" + slice[:name].dump + ", " + slice[:offset_x].to_s + ") "
      output += "_slice_offset_y(" + slice[:name].dump + ", " + slice[:offset_y].to_s + ");"
      output += "background-repeat: " + slice[:repeat]
      return output
    end
    
    def handle_slice_include
      scanner = @scanner
      scanner.scan /@include slice\s*/

      slice = parse_argument_list

      # the image could be quoted or not; in any case, use parse_string to
      # parse it. Sure, at the moment, we don't parse quoted strings properly,
      # but it should work for most cases. single-quoted strings are out, though...
      slice[:filename] = parse_string(slice[0])

      # now that we have all of the info, we can get the actual slice information.
      # This process will create a slice entry if needed.
      return generate_slice_include(slice)
    end

    def should_include_slice?(slice)
      return true if slice[:width].nil?
      return true if slice[:height].nil?

      return false if slice[:width] == 0
      return false if slice[:height] == 0

      return true
    end

    def slice_layout(slice)
      output = ""

      layout_properties = [:left, :top, :right, :bottom]

      if not slice[:repeat].nil?
        output += "background-repeat: " + slice[:repeat] + "; \n"
      end

      if slice[:right].nil? or slice[:left].nil?
        layout_properties.push(:width)
      end

      if slice[:bottom].nil? or slice[:top].nil?
        layout_properties.push(:height)
      end

      layout_properties.each {|prop|
        unless slice[prop].nil? 
          output += prop.to_s + ": " + slice[prop].to_s + "px; \n"
        end
      }

      return output
    end

    def handle_slices
      scanner = @scanner
      scanner.scan /@include slices\s*/

      arguments = parse_argument_list

      # slices() only supports four-param, left top right bottom rectangles.
      [:top, :left, :bottom, :right].each {|key|
        arguments[key] = Integer(arguments[key]) if not arguments[key].nil?
        arguments[key] = 0 if arguments[key].nil?
      }
      
      values = arguments.values

      left = arguments[:left]
      top = arguments[:top]
      right = arguments[:right]
      bottom = arguments[:bottom]

      # determine fill method
      fill = arguments[:fill] || "1 0"
      fill = fill.strip.split(/\s+/)
      fill_width = Integer(fill[0])
      fill_height = Integer(fill[1])

      skip_top_left = values.include? 'skip-top-left'
      skip_top = values.include? 'skip-top'
      skip_top_right = values.include? 'skip-top-right'
      
      skip_left = values.include? 'skip-left'
      skip_middle = values.include? 'skip-middle'
      skip_right = values.include? 'skip-right'
      
      skip_bottom_left = values.include? 'skip-bottom-left'
      skip_bottom = values.include? 'skip-bottom'
      skip_bottom_right = values.include? 'skip-bottom-right'

      filename = parse_string(arguments[0])

      # we are going to form 9 slices. If any are empty we'll skip them

      # top-left
      top_left_slice = { 
        :left => 0, 
        :top => 0,
        :width => left,
        :height => top,
        :sprite_anchor => arguments[:"top-left-anchor"],
        :sprite_padding => arguments[:"top-left-padding"],
        :offset => arguments[:"top-left-offset"],
        :filename => filename
      }

      left_slice = {
        :left => 0,
        :top => top,
        :width => left,

        :sprite_anchor => arguments[:"left-anchor"],
        :sprite_padding => arguments[:"left-padding"],
        :offset => arguments[:"left-offset"],
        :filename => filename,
        :repeat => fill_height == 0 ? nil : "repeat-y"


        # we fill in either height or bottom, depending on fill
      }

      bottom_left_slice = {
        :left => 0,
        :bottom => 0,
        :width => left,
        :height => bottom,

        :sprite_anchor => arguments[:"bottom-left-anchor"],
        :sprite_padding => arguments[:"bottom-left-padding"],
        :offset => arguments[:"bottom-left-offset"],
        :filename => filename


      }

      top_slice = {
        :left => left,
        :top => 0,
        :height => top,

        :sprite_anchor => arguments[:"top-anchor"],
        :sprite_padding => arguments[:"top-padding"],
        :offset => arguments[:"top-offset"],
        :filename => filename,
        :repeat => fill_width == 0 ? nil : "repeat-x"



        # we fill in either width or right, depending on fill
      }

      middle_slice = {
        :left => left,
        :top => top,

        :sprite_anchor => arguments[:"middle-anchor"],
        :sprite_padding => arguments[:"middle-padding"],
        :offset => arguments[:"middle-offset"],
        :filename => filename,
        :repeat => fill_height != 0 ? (fill_width != 0 ? "repeat-both" : "repeat-y") : (fill_width != 0 ? "repeat-x" : nil)


        # fill in width, height or right, bottom depending on fill settings
      }

      bottom_slice = {
        :left => left,
        :bottom => 0,
        :height => bottom,

        :sprite_anchor => arguments[:"bottom-anchor"],
        :sprite_padding => arguments[:"bottom-padding"],
        :offset => arguments[:"bottom-offset"],
        :filename => filename,
        :repeat => fill_width == 0 ? nil : "repeat-x"



        # we fill in width or right depending on fill settings
      }

      top_right_slice = {
        :right => 0,
        :top => 0,
        :width => right,
        :height => top,

        :sprite_anchor => arguments[:"top-right-anchor"],
        :sprite_padding => arguments[:"top-right-padding"],
        :offset => arguments[:"top-right-offset"],
        :filename => filename


      }

      right_slice = {
        :right => 0,
        :top => top,
        :width => right,

        :sprite_anchor => arguments[:"right-anchor"],
        :sprite_padding => arguments[:"right-padding"],
        :offset => arguments[:"right-offset"],
        :filename => filename,

        :repeat => fill_height == 0 ? nil : "repeat-y"


        # we fill in either height or top depending on fill settings
      }

      bottom_right_slice = {
        :right => 0,
        :bottom => 0,
        :width => right,
        :height => bottom,

        :sprite_anchor => arguments[:"bottom-right-anchor"],
        :sprite_padding => arguments[:"bottom-right-padding"],
        :offset => arguments[:"bottom-right-offset"],
        :filename => filename


      }

      if fill_width == 0
        top_slice[:right] = right
        middle_slice[:right] = right
        bottom_slice[:right] = right
      else
        top_slice[:width] = fill_width
        middle_slice[:width] = fill_width
        bottom_slice[:width] = fill_width
      end

      if fill_height == 0
        left_slice[:bottom] = bottom
        middle_slice[:bottom] = bottom
        right_slice[:bottom] = bottom
      else
        left_slice[:height] = fill_height
        middle_slice[:height] = fill_height
        right_slice[:height] = fill_height
      end

      output = ""

      # LEFT
      if should_include_slice?(top_left_slice) and not skip_top_left
        output += ".top-left {\n"
        output += generate_slice_include(top_left_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(top_left_slice)

        output += "}\n"
      end

      if should_include_slice?(left_slice) and not skip_left
        output += ".left {\n"
        output += generate_slice_include(left_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(left_slice.merge({ :bottom => bottom }))

        output += "}\n"
      end

      if should_include_slice?(bottom_left_slice) and not skip_bottom_left
        output += ".bottom-left {\n"
        output += generate_slice_include(bottom_left_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(bottom_left_slice)

        output += "}\n"
      end

      # MIDDLE
      if should_include_slice?(top_slice) and not skip_top
        output += ".top {\n"
        output += generate_slice_include(top_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(top_slice.merge({ :right => right }))

        output += "}\n"
      end

      if should_include_slice?(middle_slice) and not skip_middle
        output += ".middle {\n"
        output += generate_slice_include(middle_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(middle_slice.merge({ :bottom => bottom, :right => right }))


        output += "}\n"
      end

      if should_include_slice?(bottom_slice) and not skip_bottom
        output += ".bottom {\n"
        output += generate_slice_include(bottom_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(bottom_slice.merge({ :right => right }))


        output += "}\n"
      end

      # RIGHT
      if should_include_slice?(top_right_slice) and not skip_top_right
        output += ".top-right {\n"
        output += generate_slice_include(top_right_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(top_right_slice)

        output += "}\n"
      end

      if should_include_slice?(right_slice) and not skip_right
        output += ".right {\n"
        output += generate_slice_include(right_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(right_slice.merge({ :bottom => bottom }))

        output += "}\n"
      end

      if should_include_slice?(bottom_right_slice) and not skip_bottom_right
        output += ".bottom-right {\n"
        output += generate_slice_include(bottom_right_slice) + ";"

        output += "\nposition: absolute;\n"
        output += slice_layout(bottom_right_slice)

        output += "}\n"
      end

      return output
    end
  end
end

