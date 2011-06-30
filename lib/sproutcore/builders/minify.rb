# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"
require 'fileutils'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::Minify < Builder::Base

    # main entry called by build tasls
    def self.build(entry, dst_path, kind)
      new(entry, kind).build(dst_path)
    end

    def initialize(entry=nil, kind=nil)
      super(entry)
      @kind = kind
    end

    # override this method in subclasses to actually do build
    def build(dst_path)
      send("build_#{@kind}".to_sym, dst_path)
    end

    # Minify some javascript by invoking the YUI compressor.
    def build_javascript(dst_path)
      entry.source_entry.build!

      # Minify module JavaScript immediately so it can be string-wrapped
      if entry.target[:target_type] == :module
        SC::Helpers::Minifier.minify dst_path
      elsif entry.target[:target_type] == :app
        SC::Helpers::Minifier << dst_path
      end
    end
    
    def build_html(dst_path)
      entry.source_entry.build!
      SC::Helpers::Minifier << dst_path
    end

  private

    def _report_error(output, input_filename, input_filepath)
      # The output might have some clues to what exactly was wrong, and it'll
      # be convenient for users if we include the subset.  So we'll read the
      # line numbers from any output lines that start with "[ERROR]" those
      # lines, too.
      if output
        parsed_a_line = false
        output.each_line { |output_line|
          output_line = output_line.chomp
          if (output_line =~ /^\[ERROR\] (\d+):(\d+):.*/) != nil
            line_number = $1
            position    = $2
            parsed_a_line = true
            if ( position  &&  position.to_i > 0 )
              # Read just that line and output it.
              # (sed -n '3{;p;q;}' would probably be faster, but not
              # universally available)
              line_number  = line_number.to_i
              line_counter = 1
              begin
                file = File.new(input_filepath, "r")
                outputted_line = false
                previous_line = nil
                while (file_line = file.gets)

                  if ( line_counter == line_number )
                    message = "YUI compressor error:  #{output_line} on line #{line_number} of #{input_filename}:\n"
                    if !previous_line.nil?
                      message += "        [#{line_number - 1}]  #{previous_line}"
                    end
                    message   += "   -->  [#{line_number}]  #{file_line}"

                    SC.logger.error message
                    outputted_line = true
                    break
                  else
                    previous_line = file_line
                  end
                  line_counter += 1
                end
                file.close
              rescue => err
                SC.logger.error "Could not read the actual line from the file:  #{err}"
              end

              if !outputted_line
                SC.logger.error "YUI compressor error:  #{output_line}, but couldn't read that line in the input file"
              end
            end
          end
        }

        # If we didn't handle at least one line of output specially, then
        # just output it all.
        if !parsed_a_line
          SC.logger.error output
        end
      end
    end


  end

end
