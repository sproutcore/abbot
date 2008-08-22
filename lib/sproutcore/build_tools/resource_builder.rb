module SproutCore

  module BuildTools

    # The ResourceBuilder can combine all of the source files listed in the 
    # passed entry including some basic pre-processing.  The JavaScriptBuilder 
    # extends this to do some JavaScript specific rewriting of URLs, etc. as 
    # well.
    #
    # The ResourceBuilder knows how
    class ResourceBuilder

      attr_reader :bundle, :language, :filenames

      # Utility method you can call to get the items sorted by load order
      def self.sort_entries_by_load_order(entries, language, bundle)
        filenames = entries.map { |e| e.filename }
        hashed = {}
        entries.each { |e| hashed[e.filename] = e }

        sorted = self.new(filenames, language, bundle).required
        sorted.map { |filename| hashed[filename] }
      end

      def initialize(filenames, language, bundle)
        @bundle = bundle; @language = language; @filenames = filenames
      end

      # Simply returns the filenames in the order that they were required
      def required
        lines = []; required = []
        while filename = next_filename
          lines, required = _build_one(filename, lines, required, true)
        end
        return lines
      end

      # Actually perform the build.  Returns the compiled resource as a single string.
      def build

        # setup context
        lines = []
        required = []

        # process files
        while filename = next_filename
          lines, required = _build_one(filename, lines, required)
        end

        return join(lines)
      end

      # Join the lines together.  This is one last chance to do some prep of
      # the data (such as minifcation and comment stripping)
      # TODO: compress CSS
      def join(lines); lines.join; end

      # Rewrites any inline content such as static urls.  Subclasseses can
      # override this to rewrite any other inline content.
      #
      # The default will rewrite calls to static_url().
      def rewrite_inline_code(line, filename)
        line.gsub(/static_url\([\'\"](.+?)[\'\"]\)/) do | rsrc |
          entry = bundle.find_resource_entry($1, :language => language)
          static_url(entry.nil? ? '' : entry.cacheable_url)
        end
      end

      # Tries to build a single resource.  This may call itself recursively to
      # handle requires.
      #
      # ==== Returns
      # [lines, required] to be passed into the next call
      #
      def _build_one(filename, lines, required, link_only = false)
        return [lines, required] if required.include?(filename)
        required << filename

        entry = bundle.entry_for(filename, :hidden => :include, :language => language)
        if entry.nil?
          puts "WARNING: Could not find require file: #{filename}"
          return [lines, required]
        end

        file_lines = []
        io = (entry.source_path.nil? || !File.exists?(entry.source_path)) ? [] : File.new(entry.source_path)
        io.each do | line |

          # check for requires.  Only follow a require if the require is in
          # the list of filenames.
          required_file = _require_for(filename, line)
          unless required_file.nil? || !filenames.include?(required_file)
            lines, required = _build_one(required_file, lines, required, link_only)
          end

          file_lines << rewrite_inline_code(line, filename) unless link_only
        end

        # The list of already required filenames is slightly out of order from
        # the actual load order.  Instead, we use the lines array to hold the
        # list of filenames as they are processed.
        if link_only
          lines << filename

        elsif file_lines.size > 0
          
          if entry.ext == "sass"
            file_lines = [ compile_sass(entry, file_lines.join()) ]
          end
          
          lines << "/* Start ----------------------------------------------------- " << filename << "*/\n\n" 
          lines +=  file_lines
          lines << "\n\n/* End ------------------------------------------------------- "  << filename << "*/\n\n"
        end

        return [lines, required]
      end

      # Overridden by subclasses to choose first filename.
      def next_filename; filenames.delete(filenames.first); end

      # Overridden by subclass to handle static_url() in a language specific
      # way.
      def static_url(url); "url('#{url}')"; end

      # check line for required() pattern.  understands JS and CSS.
      def _require_for(filename,line)
        new_file = line.scan(/require\s*\(\s*['"](.*)(\.(js|css))?['"]\s*\)/)
        ret = (new_file.size > 0) ? new_file.first.first : nil
        ret.nil? ? nil : filename_for_require(ret)
      end

      def filename_for_require(ret); "#{ret}.css"; end

      private

      def compile_sass(entry, content)
          require 'sass'
          begin
            Sass::Engine.new(content).render
          rescue Exception => e
            e_string = "#{e.class}: #{e.message}"
            if e.is_a? Sass::SyntaxError
              e_string << "\non line #{e.sass_line}"
              e_string << " of #{entry.source_path}"
              if File.exists?(entry.source_path)
                e_string << "\n\n"
                min = [e.sass_line - 5, 0].max
                File.read(entry.source_path).rstrip.split("\n")[
                  min .. e.sass_line + 5
                ].each_with_index do |line, i|
                  e_string << "#{min + i + 1}: #{line}\n"
                end
              end
            end
<<END
/*
#{e_string}

Backtrace:\n#{e.backtrace.join("\n")}
*/
body:before {
  white-space: pre;
  font-family: monospace;
  content: "#{e_string.gsub('"', '\"').gsub("\n", '\\A ')}"; }
END
          end
      end



    end

    class JavaScriptResourceBuilder < ResourceBuilder

      # Final processing of file.  Remove comments & minify
      def join(lines)

        if bundle.minify?
          # first suck out any comments that should be retained
          comments = []
          include_line = false
          lines.each do | line |
            is_mark = (line =~ /@license/)
            unless include_line
              include_line = true if is_mark
              is_mark = false
            end

            comments << line if include_line
            include_line = false if include_line && is_mark
          end

          # now minify and prepend any static
          comments.push "\n" unless comments.empty?
          comments.push SproutCore::JSMin.run(lines * '')
          lines = comments
        end

        lines.join
      end

      # If the file is a strings.js file, then remove server-side strings...
      def rewrite_inline_code(line, filename)
        if filename == 'strings.js'
          line = line.gsub(/["']@@.*["']\s*?:\s*?["'].*["'],\s*$/,'')
          
        else
          if line.match(/sc_super\(\s*\)/)
            line = line.gsub(/sc_super\(\s*\)/, 'arguments.callee.base.apply(this,arguments)')
          elsif line.match(/sc_super\(.+?\)/)
            puts "\nWARNING: Calling sc_super() with arguments is DEPRECATED. Please use sc_super() only.\n\n"
            line = line.gsub(/sc_super\((.+?)\)/, 'arguments.callee.base.apply(this, \1)')
          end
        end

        super(line, filename)
      end

      def static_url(url); "'#{url}'"; end
      def filename_for_require(ret); "#{ret}.js"; end

      def next_filename
        filenames.delete('strings.js') || filenames.delete('core.js') || filenames.delete('Core.js') || filenames.delete('utils.js') || filenames.delete(filenames.first)
      end

    end

    def self.build_stylesheet(entry, bundle)
      filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
      builder = ResourceBuilder.new(filenames, entry.language, bundle)
      if output = builder.build
        FileUtils.mkdir_p(File.dirname(entry.build_path))
        f = File.open(entry.build_path, 'w')
        f.write(output)
        f.close
      end
    end

    def self.build_javascript(entry, bundle)
      filenames = entry.composite? ? entry.composite_filenames : [entry.filename]
      builder = JavaScriptResourceBuilder.new(filenames, entry.language, bundle)
      if output = builder.build
        FileUtils.mkdir_p(File.dirname(entry.build_path))
        f = File.open(entry.build_path, 'w')
        f.write(output)
        f.close
      end
    end

    def self.build_fixture(entry, bundle)
      build_javascript(entry, bundle)
    end
    
    def self.build_debug(entry, bundle)
      build_javascript(entry, bundle)
    end

  end

end
