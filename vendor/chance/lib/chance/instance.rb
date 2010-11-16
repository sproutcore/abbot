require 'set'
require 'sass'
require 'compass'

require 'chance/parser'
require 'chance/imagers/data_url'
require 'chance/sass_extensions'

Compass.discover_extensions!
Compass.configure_sass_plugin!


module Chance
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
    @@round = 0

    attr_accessor :css
    
    def initialize(options = {})
      @options = options
      @options[:theme] = "" if @options[:theme].nil?
      
      if @options[:theme].length > 0 and @options[:theme][0] != "."
        @options[:theme] = "." + @options[:theme]
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

      return file_not_found(identifier) if not file

      # Not overly efficient at the moment; that above is just
      # fact-checking, as we recombine on any update() call, and
      # when we do so, we aren't doing it by keeping references to
      # the individual files; we are doing it by finding them in the
      # files hash.
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
      if not @files[path]
        file_not_found(path)
      end
      
      return Chance.get_file(@files[path])
    end

    # Generates the output CSS.
    # This combines the input CSS file(s), parses it, prepares the images,
    # and generates the final output (which it will store in css).
    def update
      css = _combine

      begin
        # SCSS code executing needs to know what the current instance of Chance is,
        # so that lookups for slices, etc. work.
        Chance._current_instance = self

        # Step 1: parse CSS
        parser = Chance::Parser.new(css, @options)
        parser.parse

        # Step 2: get parsed slices and add the CSS it generates it to parsed output CSS
        # note that it is saved to @slices so that the slices may be found by the SCSS
        # extensions that help find offset, etc.
        @slices = parser.slices
        imager = Chance::DataURLImager.new(parser.slices, self) # for now, only DataURLs
        css = parser.css + "\n" + imager.css

        # Step 3: Create output
        engine = Sass::Engine.new(css, Compass.sass_engine_options.merge({ :syntax => :scss }))
        css = engine.render
      ensure
        Chance._current_instance = nil
      end

      @css = css
    end

    # Looks up a slice that has been found by parsing the CSS. This is used by
    # the Sass extensions that handle writing things like slice offset, etc.
    def get_slice(name)
      key = @slices.keys[0]
      return @slices[name]
    end

  private

    # 
    # COMBINING CSS
    #
    #
    # _include_file is the recursive method in the depth-first-search
    # that creates the ordered list of files. The list is created in the
    # variable @file_list.
    #
    def _include_file(file)
      return if not file =~ /\.css$/

      file = Chance.get_file(file)

      return if file.nil?
      return if file[:included] === @@round

      requires = file[:requires]
      requires.each {|r| _include_file(@files[r]) } unless requires.nil?

      file[:included] = @@round

      @file_list.push(file)
    end

    # _combine coordinates the combination process; it loops over the
    # raw set of files we have, and for each one, calls _include_file,
    # and finally, combines all of them into one giant string.
    def _combine
      @@round = @@round + 1
      files = @files.values
      @file_list = []

      files.each {|f| _include_file(f) }
      
      content = "$theme: '" + @options[:theme] + "';"

      content += @file_list.map {|file|
        "@_chance_file " + @files.key(file[:path]) + ";\n" + file[:content]
      }.join("\n")

      content
    end

    # a helper so that, when a file is not found, we can show a warning.
    # Our response to this error could also change in future-- a good
    # point for separating it out like this.
    def file_not_found(path)
      raise "File not mapped in Chance instance: #{path}"
    end
  end
end
