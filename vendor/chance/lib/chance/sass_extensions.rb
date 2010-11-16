require "base64"


module Sass::Script::Functions
  # utilities used by code dynamically added by the parser.
  # The parser adds _slice_offset_x/y to get the offset of a slice (which
  # may be dynamically calculated for spriting). Because apparently function
  # calls may not be used inside expressions, an amount to add to the slice
  # offset is passed in as well.
  def _slice_offset_x(slice_name, start_offset = 0)
    slice = Chance._current_instance.get_slice(slice_name.value)
    raise "Invalid slice" if slice.nil?

    return Sass::Script::Number.new(slice[:imaged_offset_x] + Integer(start_offset))
  end

  def _slice_offset_y(slice_name, start_offset = 0)
    slice = Chance._current_instance.get_slice(slice_name.value)
    raise "Invalid slice" if slice.nil?

    return Sass::Script::Number.new(slice[:imaged_offset_y] + Integer(start_offset))
  end

end
