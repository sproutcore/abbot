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

    @@generation = 0

    def initialize(options = {})
      @options = options
      @options[:theme] = "" if @options[:theme].nil?

      if @options[:theme].length > 0 and @options[:theme][0] != "."
        @options[:theme] = "." + @options[:theme].to_s
      end

      # The mapped files are a map from file names in the Chance Instance to
      # their identifiers in Chance itself.
      @mapped_files = { }

      # The @files set is a set cached generated output files, used by the output_for
      # method.
      @files = {}

      # The @slices hash maps slice names to hashes defining the slices. As the
      # processing occurs, the slice hashes may contain actual sliced image canvases,
      # may be 2x or 1x versions, etc.
      @slices = {}

      # Tracks whether _render has been called.
      @has_rendered = false
    end

    # maps a path relative to the instance to a file identifier
    # registered with chance via Chance::addFile.
    #
    # If a Chance instance represents a SproutCore language folder,
    # the relative path would be the path inside of that folder.
    # The identifier would be a name of a file that you added to
    # Chance using add_file.
    def map_file(path, identifier)
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
      path = path.to_s
      @mapped_files.delete path

      # Invalidate our render because things have changed.
      clean
    end

    # checks all files to see if they have changed
    def check_all_files
      needs_clean = false
      @mapped_files.values.each {|f|
        needs_clean = true if Chance.update_file_if_needed f
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

      @files = {}
      begin
        # SCSS code executing needs to know what the current instance of Chance is,
        # so that lookups for slices, etc. work.
        Chance._current_instance = self

        # Step 1: preprocess CSS, determining order and parsing the slices out.
        # The output of this process is a "virtual" file that imports all of the 
        # SCSS files used by this Chance instance. This also sets up the @slices hash.
        import_css = _preprocess

        # STEP 2: Preparing input CSS
        # The main CSS file we pass to the Sass Engine will have placeholder CSS for the
        # slices (the details will be postprocessed out).
        # After that, all of the individual files (using the import CSS generated
        # in Step 1)
        css = _css_for_slices + "\n" + import_css

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
        postprocess_css_sprited(opts)
      else
        postprocess_css_dataurl(opts)
      end
    end


    # 
    # COMBINING CSS
    #
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

      file = Chance.get_file(file)

      return if file.nil?
      return if file[:included] === @@generation

      requires = file[:requires]
      file[:included] = @@generation

      requires.each {|r| _include_file(@mapped_files[r]) } unless requires.nil?



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

      files.each {|f| _include_file(f) }

      relative_paths = @mapped_files.invert

      unique_number = 0

      @file_list.map {|file|
        # The parser accepts single files that contain many files. As such,
        # its method of determing the current file name is a marker in the
        # file. We may want to consider changing this to a parser option
        # now that we don't need this feature so much, but this works for now.
        content = "@_chance_file " + relative_paths[file[:path]] + ";\n"
        content += "$theme: '" + @options[:theme] + "';"
        content += file[:content]

        parser = Chance::Parser.new(content, @options)
        parser.parse
        file[:parsed_css] = parser.css

        # We used to use an md5 hash here, but this hides the original file name
        # from SCSS, which makes the file name + line number comments useless.
        #
        # Instead, we sanitize the path and put a unique number as a prefix.
        path_safe = file[:path].gsub(/[^a-zA-Z0-9\-_\\\/]/, '-')
        path_safe = File.join("#{unique_number}", "#{path_safe}")
        unique_number += 1

        tmp_path = "./tmp/chance/#{path_safe}.scss"

        FileUtils.mkdir_p(File.dirname(tmp_path))

        f = File.new(tmp_path, "w")
        f.write(parser.css)
        f.close

        css = "@import \"" + tmp_path + "\";"

        css
      }.join("\n")
    end

  end
end
