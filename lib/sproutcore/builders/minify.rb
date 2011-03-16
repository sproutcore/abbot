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

    def build_css(dst_path)
      a = Regexp.new('^'+MANIFEST.build_root)
      if dst_path =~ a
		# $to_minify << dst_path
        FileUtils.mkdir_p(File.dirname(dst_path))
        FileUtils.copy(entry.source_path, dst_path)
      else
        FileUtils.mkdir_p(File.dirname(dst_path)) # make sure loc exists...
        filecompress = "java -Xmx128m -jar \"" + SC.yui_jar + "\" --charset utf-8 --line-break 0 --nomunge --preserve-semi --disable-optimizations \"" + entry.source_path + "\" -o \"" + dst_path + "\" 2>&1"
        SC.logger.info  'Compressing CSS with YUI .... '+ dst_path
        SC.logger.debug `#{filecompress}`

        if $?.exitstatus != 0
          _report_error(output, entry.filename, entry.source_path)
          SC.logger.fatal("!!!!YUI compressor failed, please check that your css code is valid.")
          SC.logger.fatal("!!!!Failed compressing CSS... "+ dst_path)
        end
      end
  	end

    # Minify some javascript by invoking the YUI compressor.
    def build_javascript(dst_path)
      entry.source_entry.build!
      # Minify module JavaScript immediately so it can be string-wrapped
      if entry.target[:target_type] == :module
        SC::Helpers::Minifier.minify dst_path
      else
        SC::Helpers::Minifier << dst_path
      end

      puts "---------------------------------DONE WITH MINIFICATION"
    end

    def build_inline_javascript(dst_path)
      SC.logger.info  'Compiling inline Javascript with YUI: ' + dst_path + "..."
      FileUtils.mkdir_p(File.dirname(dst_path)) # make sure loc exists...
      filecompress = "java -Xmx128m -jar \"" + SC.yui_jar + "\" --js \"" + entry.source_path + "\" --js_output_file \"" + dst_path + "\" 2>&1"
      SC.logger.info  'Compiling with YUI:  '+ filecompress + "..."

      output = `#{filecompress}`      # It'd be nice to just read STDERR, but
                                      # I can't find a reasonable, commonly-
                                      # installed, works-on-all-OSes solution.
      if $?.exitstatus != 0
        _report_error(output, entry.filename, entry.source_path)
        SC.logger.fatal("!!!!YUI compiler failed, please check that your js code is valid")
        SC.logger.fatal("!!!!Failed compiling ... "+ dst_path)
      end
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
