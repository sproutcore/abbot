require 'set'
require 'compass'

require 'chance/parser'

require 'chance/perf'

require 'chance/instance/slicing'
require 'chance/instance/spriting'
require 'chance/instance/data_url'
require 'chance/instance/javascript'

require 'digest/md5'


Compass.discover_extensions!
Compass.configure_sass_plugin!


module Chance

  class FileNotFoundError < StandardError
    attr_reader :path
    def initialize(path)
      @path = path
      super(message)
    end

    def message
      "File not mapped in Chance instance: #{path}"
    end
  end

  # Chance::Instance represents an instance of the chance processor.
  # In a SproutCore package, an "instance" would likely be a language folder.
  #
  # An instance has a list of files (instance-relative paths mapped
  # to paths already registered with Chance). This collection of files
  # should include CSS files, image files, and any other kind of file
  # needed to generate the output.
  #
  # When you call update(), Chance will process everything (or
  # re-process it) and put the result in its "css" property.
  class Instance
    include Slicing
    include Spriting
    include DataURL
    include JavaScript

    CHANCE_FILES = {
      "chance.css"            => { :method => :css },
      "chance@2x.css"         => { :method => :css, :x2 => true },
      "chance-sprited.css"    => { :method => :css, :sprited => true },
      "chance-sprited@2x.css" => { :method => :css, :sprited => true, :x2 => true },

      # For Testing Purposes...
      "chance-test.css"       => { :method => :chance_test }
    }

    @@uid = 0
    
    @@generation = 0

    def initialize(options = {})
      @options = options
      @options[:theme] = "" if @options[:theme].nil?
      @options[:pad_sprites_for_debugging] = true if @options[:pad_sprites_for_debugging].nil?
      @options[:optimize_sprites] = true if @options[:optimize_sprites].nil?
      
      @@uid += 1
      @uid = @@uid
      
      @options[:instance_id] = @uid if @options[:instance_id].nil?

      if @options[:theme].length > 0 and @options[:theme][0] != "."
        @options[:theme] = "." + @options[:theme].to_s
      end

      # The mapped files are a map from file names in the Chance Instance to
      # their identifiers in Chance itself.
      @mapped_files = { }
      
      # The file mtimes are a collection of mtimes for all the files we have. Each time we
      # read a file we record the mtime, and then we compare on check_all_files
      @file_mtimes = { }

      # The @files set is a set cached generated output files, used by the output_for
      # method.
      @files = {}

      # The @slices hash maps slice names to hashes defining the slices. As the
      # processing occurs, the slice hashes may contain actual sliced image canvases,
      # may be 2x or 1x versions, etc.
      @slices = {}

      # Tracks whether _render has been called.
      @has_rendered = false
      
      # A generation number for the current render. This allows the slicing and spriting
      # to be invalidated smartly.
      @render_cycle = 0
    end

    # maps a path relative to the instance to a file identifier
    # registered with chance via Chance::addFile.
    #
    # If a Chance instance represents a SproutCore language folder,
    # the relative path would be the path inside of that folder.
    # The identifier would be a name of a file that you added to
    # Chance using add_file.
    def map_file(path, identifier)
      if @mapped_files[path] == identifier
        # Don't do anything if there is nothing to do.
        return
      end
      
      path = path.to_s
      file = Chance.has_file(identifier)

      raise FileNotFoundError.new(path) unless file

      @mapped_files[path] = identifier

      # Invalidate our render because things have changed.
      clean
    end

    # unmaps a path from its identifier. In short, removes a file
    # from this Chance instance. The file will remain in Chance's "virtual filesystem".
    def unmap_file(path)
      if not @mapped_files.include?(path)
        # Don't do anything if there is nothing to do
        return
      end
      
      path = path.to_s
      @mapped_files.delete path

      # Invalidate our render because things have changed.
      clean
    end
    
    # unmaps all files
    def unmap_all
      @mapped_files = {}
    end

    # checks all files to see if they have changed
    def check_all_files
      needs_clean = false
      @mapped_files.each {|p, f|
        mtime = Chance.update_file_if_needed(f)
        if @file_mtimes[p].nil? or mtime > @file_mtimes[p]
          needs_clean = true
        end
      }
      
      clean if needs_clean
    end

    # Using a path relative to this instance, gets an actual Chance file
    # hash, with any necessary preprocessing already performed. For instance,
    # content will have been read, and if it is an image file, will have been
    # loaded as an actual image.
    def get_file(path)
      raise FileNotFoundError.new(path) unless @mapped_files[path]

      return Chance.get_file(@mapped_files[path])
    end

    def output_for(file)
      return @files[file] if not @files[file].nil?

      # small hack: we are going to determine whether it is x2 by whether it has
      # @2x in the name.
      x2 = file.include? "@2x"

      opts = CHANCE_FILES[file]
      if opts
        send opts[:method], opts
      elsif sprite_names({ :x2 => x2 }).include? file
        return sprite_data({:name => file, :x2 => x2 })
      else
        raise "Chance does not generate a file named '#{file}'" if opts.nil?
      end
    end

    # Generates CSS output according to the options provided.
    #
    # Possible options:
    #
    #   :x2         If true, will generate the @2x version.
    #   :sprited    If true, will use sprites rather than data uris.
    #
    def css(opts)
      _render

      slice_images(opts)

      _postprocess_css opts
    end

    # Looks up a slice that has been found by parsing the CSS. This is used by
    # the Sass extensions that handle writing things like slice offset, etc.
    def get_slice(name)
      return @slices[name]
    end

    # Cleans the current render, getting rid of all generated output.
    def clean
      @has_rendered = false
      @files = {}
    end

  private

    # Generates output for tests.
    def chance_test(opts)
       ".hello { background: static_url('test.png'); }"
    end

    # Processes the input CSS, producing CSS ready for post-processing.
    # This is the first step in the Chance build process, and is usually
    # called by the output_for() method. It produces a raw, unfinished CSS file.
    def _render
      return if @has_rendered

      # Update the render cycle to invalidate sprites, slices, etc.
      @render_cycle = @render_cycle + 1
      
      @files = {}
      begin
        # SCSS code executing needs to know what the current instance of Chance is,
        # so that lookups for slices, etc. work.
        Chance._current_instance = self

        # Step 1: preprocess CSS, determining order and parsing the slices out.
        # The output of this process is a "virtual" file that imports all of the 
        # SCSS files used by this Chance instance. This also sets up the @slices hash.
        import_css = _preprocess
        
        # Because we encapsulate with instance_id, we should not have collisions even IF another chance
        # instance were running at the same time (which it couldn't; if it were, there'd be MANY other issues)
        image_css_path = File.join('./tmp/chance/image_css', @options[:instance_id].to_s, '_image_css.scss')
        FileUtils.mkdir_p(File.dirname(image_css_path))
        
        file = File.new(image_css_path, "w")
        file.write(_css_for_slices)
        file.close
        
        image_css_path = File.join('./tmp/chance/image_css', @options[:instance_id].to_s, 'image_css')
        

        # STEP 2: Preparing input CSS
        # The main CSS file we pass to the Sass Engine will have placeholder CSS for the
        # slices (the details will be postprocessed out).
        # After that, all of the individual files (using the import CSS generated
        # in Step 1)
        css = "@charset \"UTF-8\";\n@import \"#{image_css_path}\";\n" + import_css

        # Step 3: Apply Sass Engine
        engine = Sass::Engine.new(css, Compass.sass_engine_options.merge({
          :syntax => :scss,
          :filename => "chance_main.css",
          :cache_location => "./tmp/sass-cache",
          :style => @options[:minify] ? :compressed : :expanded
        }))
        css = engine.render

        @css = css
        @has_rendered = true
      ensure
        Chance._current_instance = nil
      end
    end

    # Creates CSS for the slices to be provided to SCSS.
    # This CSS is incomplete; it will need postprocessing. This CSS
    # is generated with the set of slice definitions in @slices; the actual
    # slicing operation has not yet taken place. The postprocessing portion
    # receives sliced versions.
    def _css_for_slices

      output = []
      slices = @slices

      slices.each do |name, slice|
        # Write out comments specifying all the files the slice is used from
        output << "/* Slice #{name}, used in: \n"
        slice[:used_by].each {|used_by|
          output << "\t#{used_by[:path]}\n"
        }
        output << "*/"

        output << "." + slice[:css_name] + " { "
        output << "_sc_chance: \"#{name}\";"
        output << "} \n"
      end

      return output.join ""

    end

    # Postprocesses the CSS using either the spriting postprocessor or the
    # data url postprocessor, as specified by opts.
    #
    # Opts:
    #
    # :x2 => whether to generate @2x version.
    # :sprited => whether to use spriting instead of data uris.
    def _postprocess_css(opts)
      if opts[:sprited]
        ret = postprocess_css_sprited(opts)
      else
        ret = postprocess_css_dataurl(opts)
      end
      
      ret = _strip_slice_class_names(ret)
    end
    
    #
    # Strips dummy slice class names that were added by Chance so that SCSS could do its magic,
    # but which are no longer needed.
    #
    def _strip_slice_class_names(css)
      css.gsub! /\.__chance_slice[^{]*?,/, ""
      css
    end


    # 
    # COMBINING CSS
    #
    
    # Determines the "Chance Header" to add at the beginning of the file. The
    # Chance Header can set, for instance, the $theme variable.
    #
    # The Chance Header is loaded from the nearest _theme.css file in this folder
    # or a containing folder (the file list specifically ignores such files; they are
    # only used for this purpose)
    #
    # For backwards-compatibility, the fallback if no _theme.css file is present
    # is to return code setting $theme to the now-deprecated @options[:theme] 
    # passed to Chance
    def chance_header_for_file(file)
      # 'file' is the name of a file, so we actually need to start at dirname(file)
      dir = File.dirname(file)
      
      # This should not be slow, as this is just a hash lookup
      while dir.length > 0 and not dir == "."
        header_file = @mapped_files[File.join(dir, "_theme.css")]
        if not header_file.nil?
          return Chance.get_file(header_file)
        end
        
        dir = File.dirname(dir)
      end
      
      # Make sure to look globally
      header_file = @mapped_files["_theme.css"]
      return Chance.get_file(header_file) if not header_file.nil?
      
      {
        # Never changes (without a restart, at least)
        :mtime => 0,
        :content => "$theme: '" + @options[:theme] + "';\n"
      }
    end
    
    #
    # _include_file is the recursive method in the depth-first-search
    # that creates the ordered list of files.
    #
    # To determine if a file is already included, we use the class variable
    # "generation", which we increment each pass.
    #
    # The list is created in the variable @file_list.
    #
    def _include_file(file)
      return if not file =~ /\.css$/
      
      # skip _theme.css files
      return if file =~ /_theme\.css$/

      file = Chance.get_file(file)

      return if file.nil?
      return if file[:included] === @@generation

      requires = file[:requires]
      file[:included] = @@generation

      if not requires.nil?
        requires.each {|r|
          # Add the .css extension if needed. it is optional for sc_require
          r = r + ".css" if not r =~ /\.css$/
          _include_file(@mapped_files[r])
        }
      end



      @file_list.push(file)
    end

    # Determines the order of the files, parses them using the Chance parser,
    # and returns a file with an SCSS @import directive for each file.
    #
    # It also creates and fills in the @slices hash.
    def _preprocess
      @slices = {}
      @options[:slices] = @slices

      @@generation = @@generation + 1
      files = @mapped_files.values
      @file_list = []
      
      # We have to sort alphabetically first...
      tmp_file_list = []
      @mapped_files.each {|p, f| tmp_file_list.push([p, f]) }
      tmp_file_list.sort_by! {|a| a[0] }

      tmp_file_list.each {|paths|
        p, f = paths
        
        # Save the mtime for caching
        mtime = Chance.update_file_if_needed(f)
        @file_mtimes[p] = mtime
        
        _include_file(f)
      }

      relative_paths = @mapped_files.invert
      css = "@charset=\"UTF-8\";\n"

      @file_list.map {|file|
        # NOTE: WE MUST CALL CHANCE PARSER NOW, because it generates our slicses.
        # We can't be picky and just call it if something has changed. Thankfully,
        # parser is fast. Unlike SCSS.
        header_file = chance_header_for_file(relative_paths[file[:path]])
        
        content = "@_chance_file " + relative_paths[file[:path]] + ";\n"
        content += header_file[:content]
        content += file[:content]

        parser = Chance::Parser.new(content, @options)
        parser.parse
        file[:parsed_css] = parser.css
        
        # We used to use an md5 hash here, but this hides the original file name
        # from SCSS, which makes the file name + line number comments useless.
        #
        # Instead, we sanitize the path.
        path_safe = file[:path].gsub(/[^a-zA-Z0-9\-_\\\/]/, '-')

        tmp_path = "./tmp/chance/#{path_safe}.scss"

        FileUtils.mkdir_p(File.dirname(tmp_path))
        
        if (not file[:mtime] or not file[:wtime] or file[:wtime] < file[:mtime] or
            not header_file[:mtime] or file[:wtime] < header_file[:mtime])
          f = File.new(tmp_path, "w")
          f.write(parser.css)
          f.close
          file[:wtime] = Time.now.to_f
        end

        css = "@import \"" + tmp_path + "\";"

        css
      }.join("\n")
    end

  end
end
