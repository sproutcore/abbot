require 'set'
require 'compass'

require 'chance/parser'
require 'chance/imagers/data_url'
require 'chance/sass_extensions'

require 'chance/perf'
require 'chance/slicing'



Compass.discover_extensions!
Compass.configure_sass_plugin!


module Chance

  class FileNotFoundError < StandardError
    attr_reader :path
    def initialize(path)
      @path = path
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
    
    @@generation = 0

    attr_accessor :css
    
    def initialize(options = {})
      @options = options
      @options[:theme] = "" if @options[:theme].nil?
      
      if @options[:theme].length > 0 and @options[:theme][0] != "."
        @options[:theme] = "." + @options[:theme].to_s
      end
      
      @files = { }
      @css = nil
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

      @files[path] = identifier
    end

    # unmaps a path from its identifier. In short, removes a file
    # from this Chance instance. The file will remain in Chance's "virtual filesystem".
    def unmap_file(path)
      path = path.to_s
      @files.delete path
    end

    # Using a path relative to this instance, gets an actual Chance file
    # hash, with any necessary preprocessing already performed. For instance,
    # content will have been read, and if it is an image file, will have been
    # loaded as an actual image.
    def get_file(path)
      raise FileNotFoundError.new(path) unless @files[path]
      
      return Chance.get_file(@files[path])
    end

    # Generates the output CSS.
    # This parses the imput files, prepares the images, and runs the CSS
    # through SCSS. The resulting CSS is saved in the css attribute.
    def update
      begin
        # SCSS code executing needs to know what the current instance of Chance is,
        # so that lookups for slices, etc. work.
        Chance._current_instance = self

        # Step 1: preprocess CSS, determining order and parsing the slices out.
        # The output of this process is a "virtual" file that imports all of the 
        # SCSS files used by this Chance instance. This also sets up the @slices hash.
        import_css = _preprocess
        
        # Step 2: Slice images. The sliced canvases are saved in the individual slice
        # hashes.
        slice_images
        
        # Step 3: Generate CSS and images needed for output. For now, we hard-code
        # data url imager. Later, we will have a spriting imager.
        @imager = Chance::DataURLImager.new(@slices, self)
        
        # The main CSS file we pass to the Sass Engine will import the CSS the imager
        # created, and then all of the individual files (using the import CSS generated
        # in Step 1)
        # 

        # Importer, if we support it; we'll just keep it off for now.
        # if Chance::SUPPORTS_IMPORTERS
        #   importer = Importer.new(@imager)
        #   css = "@import 'chance_images';\n" + import_css
        #   cache_store = Sass::CacheStores::Filesystem.new("./tmp/.scss-cache")
        # else
          importer = nil
          css = @imager.css + "\n" + import_css
          cache_store = nil
        # end

        # Step 4: Apply Sass Engine
        engine = Sass::Engine.new(css, Compass.sass_engine_options.merge({
          :syntax => :scss,
          :importer => importer,
          :filename => "chance_main.css",
          :cache_store => cache_store
        }))
        
        css = engine.render
      ensure
        Chance._current_instance = nil
      end

      @css = css
    end
    
    # Looks up a slice that has been found by parsing the CSS. This is used by
    # the Sass extensions that handle writing things like slice offset, etc.
    def get_slice(name)
      return @slices[name] 
    end

  private

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
      requires.each {|r| _include_file(@files[r]) } unless requires.nil?

      file[:included] = @@generation

      @file_list.push(file)
    end

    # Determines the order of the files, parses them using the Chance parser,
    # and returns a file with an SCSS @import directive for each file.
    def _preprocess
      @slices = {}
      @options[:slices] = @slices
      
      @@generation = @@generation + 1
      files = @files.values
      @file_list = []

      files.each {|f| _include_file(f) }

      @file_list.map {|file|
        # The parser accepts single files that contain many files. As such,
        # its method of determing the current file name is a marker in the
        # file. We may want to consider changing this to a parser option
        # now that we don't need this feature so much, but this works for now.
        content = "@_chance_file " + @files.index(file[:path]) + ";\n"
        content += "$theme: '" + @options[:theme] + "';"
        content += file[:content]
        
        parser = Chance::Parser.new(content, @options)
        parser.parse
        file[:parsed_css] = parser.css
        
        # NO IMPORTERS FOR NOW
        #if Chance::SUPPORTS_IMPORTERS
        #  css = "@import \"" + file [:path] + ".scss\";"
        #else
          tmp_path = "./tmp/chance/" + file[:path] + ".scss"
          FileUtils.mkdir_p(File.dirname(tmp_path))
          
          f = File.new(tmp_path, "w")
          f.write(parser.css)
          f.close
          
          css = "@import \"" + tmp_path + "\";"
        # end
        
        css
      }.join("\n")
    end

  end
end
