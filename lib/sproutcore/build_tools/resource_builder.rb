module SproutCore
  
  module BuildTools

    # Set to override the default behavior (which will follow the build mode)
    def self.minify?; @minify.nil? ? (Bundle.build_mode != :development) : @minify; end
    def self.minify=(setting); @minify = setting; end
    
    # The ResourceBuilder can combine all of the source files listed in the passed entry
    # including some basic pre-processing.  The JavaScriptBuilder extends this to do some
    # JavaScript specific rewriting of URLs, etc. as well.
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
      
      # Join the lines together.  This is one last chance to do some prep of the data
      # (such as minifcation and comment stripping)
      def join(lines); lines.join; end
      
      # Tries to build a single resource.  This may call itself recursively to handle
      # requires.
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
          
          # check for requires.  Only follow a require if the require is in the list
          # of filenames.
          required_file = _require_for(filename, line) 
          unless required_file.nil? || !filenames.include?(required_file)
            lines, required = _build_one(required_file, lines, required, link_only)
          end
          
          file_lines << _rewrite_static_urls(line) unless link_only 
        end

        # The list of already required filenames is slightly out of order from the actual
        # load order.  Instead, we use the lines array to hold the list of filenames as they
        # are processed.
        if link_only
          lines << filename
          
        elsif file_lines.size > 0
          lines += file_lines
          lines << "\n"
        end
        
        return [lines, required]
      end

      # Overridden by subclasses to choose first filename.
      def next_filename; filenames.delete(filenames.first); end

      # This will look for calls to static_url() and rewrite them with an actual
      # string to the URL. Assumes the input text is JavaScript or CSS.
      def _rewrite_static_urls(line)
        line.gsub(/static_url\([\'\"](.+)[\'\"]\)/) do | rsrc |
          entry = bundle.find_resource_entry($1, :language => language)
          static_url(entry.nil? ? '' : entry.url)
        end
      end

      # Overridden by subclass to handle static_url() in a language specific way.
      def static_url(url); "url('#{url}')"; end
      
      # check line for required() pattern.  understands JS and CSS.
      def _require_for(filename,line)
        new_file = line.scan(/require\(['"](.*)['"]\)/)
        ret = (new_file.size > 0) ? new_file.first.first : nil 
        ret.nil? ? nil : filename_for_require(ret)
      end
      
      def filename_for_require(ret); "#{ret}.css"; end
      
    end

    class JavaScriptResourceBuilder < ResourceBuilder

      # Final processing of file.  Remove comments & minify
      def join(lines)

        if BuildTools.minify?
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
      
      def static_url(url); "'#{url}'"; end
      def filename_for_require(ret); "#{ret}.js"; end
      
      def next_filename
        filenames.delete('strings.js') || filenames.delete('core.js') || filenames.delete('Core.js') || filenames.delete('utils.js') || filenames.delete(filenames.first)
      end
      
    end
    
    def self.build_stylesheet(entry, bundle)
      filenames = entry.composite.nil? ? [entry.filename] : entry.composite
      builder = ResourceBuilder.new(filenames, entry.language, bundle) 
      if output = builder.build
        FileUtils.mkdir_p(File.dirname(entry.build_path))
        f = File.open(entry.build_path, 'w')
        f.write(output)
        f.close
      end
    end

    def self.build_javascript(entry, bundle)
      filenames = entry.composite.nil? ? [entry.filename] : entry.composite
      builder = JavaScriptResourceBuilder.new(filenames, entry.language, bundle) 
      if output = builder.build
        FileUtils.mkdir_p(File.dirname(entry.build_path))
        f = File.open(entry.build_path, 'w')
        f.write(output)
        f.close
      end
    end
    
    def self.build_fixture(entry, bundle); build_javascript(entry, bundle); end
    
  end
  
end