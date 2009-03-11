require 'extlib'

module SC
  
  # A generator is a special kind of project that can process some input 
  # templates to generate some default content in a target project.
  #
  # === Setup Process
  #
  # When a generator is created, the generator's environment is setup accoding
  # to the following process:
  #
  #  1. Process any passed :arguments hash (also saved as 'arguments')
  #  2. Invoke any defined generator:prepare task to do further set'
  #  3. Search the target project for a target with the target_name if set.
  #  
  #
  # === Standard Options
  #
  # These options are automatically added to the generator if possible.  Your
  # generator code should expect to work with them.  The following examples
  # assume you pass as an argument either "AddressBook.Contact" or 
  # "address_book/contact".
  #
  #  target_name:: 
  #    the name of the target to use as the root.  Defaults to the snake case
  #    version of the passed namepace.  This can be overridden by passing the
  #    "target_name" option to new().  example: "address_book"
  #
  #  target::
  #    If target_name is not nil and a target is found with a matching name,
  #    then this will be set to that target.  example: Target(/address_book)
  #
  #  build_root::
  #    If target is not nil, set to the source_root for the target.  If no
  #    target, set to the project_root for the current target project.  If no
  #    project is defined, set to the current working directory.  May be 
  #    overridden with build_root option to new().  example:
  #    /Users/charles/projects/my_project/apps/address_book
  #
  #  filename::
  #    The filename as passed in arguments.  example: "contact"
  # 
  #  namespace::
  #    The classified version of the target name.  example: "AddressBook"
  #
  #  class_name::
  #    The classified version of the filename.  example: "Contact"
  #
  #  method_name::
  #    If a full three-part Namespace.ClassName.methodName is passed, this 
  #    property will be set to the method name.  example: nil (no method name
  #    included)
  #
  class Generator < HashStruct
    
    # the target project to build in or nil if no target provided
    attr_reader :target_project

    attr_reader :logger
    
    ################################################
    ## SETUP
    ##
    
    # Creates a new generator.  Expects you to pass at least a generator name
    # and additional options including the current target project.  This will
    # search for a generator source directory in the target project and any
    # parent projects.  The source directory must live inside a folder called
    # "gen" or "generators".  The source directory must contain a Buildfile 
    # and a templates directory to be considered a valid generator.
    #
    # If no valid generator can be found matching the generator name, this 
    # method will return null
    #
    def self.load(generator_name, opts={})
      
      # get the project to search and look for the generator
      target_project = project = opts[:target_project] || SC.builtin_project
      path = ret = nil
      
      # attempt to discover the the generator
      while project && path.nil?
        %w(generators sc_generators gen).each do |dirname|
          path = File.join(project.project_root, dirname, generator_name)
          if File.directory?(path)
            has_buildfile = File.exists?(path / 'Buildfile')
            has_templates = File.directory?(path / 'templates')
            break if has_buildfile && has_templates
          end
          path = nil
        end
        project = project.parent_project
      end
      
      # Create project if possible
      ret = self.new(generator_name, opts.merge(:source_root => path, :target_project => target_project)) if path
      return ret 
    end  
      
    def initialize(generator_name, opts = {})
      super()
      
      @target_project = opts[:target_project] || opts['target_project']
      @logger = opts[:logger] || opts['logger'] || SC.logger 
      @buildfile = nil

      # delete special options
      %w(target_project logger).each do |key|
        opts.delete(key)
        opts.delete(key.to_sym)
      end
      
      # copy any remaining options onto generator
      opts.each { |key, value| self[key] = value }
      self.generator_name = generator_name
      
    end

    ################################################
    ## Buildfile
    ##
    
    # The current buildfile for the generator.  The buildfile is calculated by
    # merging the buildfile for the generator with the default generator 
    # buildfile.  Buildfiles should be named "Buildfile" and should be placed
    # in the generator root directory.
    #
    # === Returns
    #  Buildfile instance
    #
    def buildfile
      return @buildfile unless @buildfile.nil?

      @buildfile = Buildfile.new
      
      # First try to load the shared buildfile
      path = File.join(SC.builtin_project.project_root, 'gen', 'Buildfile')
      if !@buildfile.load!(path).loaded_paths.include?(path)
        SC.logger.warn("Could not load shared generator buildfile at #{buildfile_path}") 
      end
      
      # Then try to load the buildfile for the generator
      path = File.join(source_root, 'Buildfile')
      @buildfile.load!(path)
      
      return @buildfile
    end

    # The config for the current generator.  The config is computed by merging
    # the config settings for the current buildfile and the current build
    # environment.
    #
    # === Returns
    #  merged HashStruct
    #
    def config
      return @config ||= buildfile.config_for(:templates, SC.build_mode).merge(SC.env)
    end

    ################################################
    ## MAIN ENTRYPOINTS
    ##    
    
    # Prepares the generator state by parsing any passed arguments and then
    # invokes the 'generator:prepare' task from the Buildfile, if one exists.
    # Once a generator has been prepared, you can then build it.
    def prepare!
      return self if @is_prepared
      @is_prepared = true

      parse_arguments!
      
      has_project = target_project && target_project != SC.builtin_project 
      if target_name && has_project && target.nil?
        self.target = target_project.target_for(target_name)
      end

      # Attempt to build a reasonable default build_root.  Usually this should
      # be the target path, but if a target can't be found, use the project 
      # path.  If a project is not found or the target project is the builtin
      # project, then use the current working directory
      if target
        self.build_root = target.source_root
      else 
        self.build_root = has_project ? target_project.project_root : Dir.pwd
      end
      
      # Execute prepare task - give the generator a chance to fixup defaults
      buildfile.invoke 'generator:prepare', :generator => self
      return self
    end

    # Executes the generator based on the current config options.  Raises an 
    # exception if anything failed during the build.  This will copy each 
    # file from the source, processing it with the rhtml template.
    def build!
      prepare! # if needed
      buildfile.invoke 'generator:build', :generator => self
      return self 
    end

    ################################################
    ## LOGGING
    ##
    
    # Helper method.  Call this when an acception occurs that is fatal due to
    # a problem with the user.
    def fatal!(description)
      raise description
    end
    
    # Helper method.  Call this when you want to log an info message.  Logs to
    # the standard logger.
    def info(description); logger.info(description); end
    
    # Helper method.  Call this when you want to log a debug message.
    def debug(description); logger.debug(description); end
    
    # Log this when you need to issue a warning.
    def warn(description); logger.warn(description); end
    
    
    # Logs the pass file to the logger after first processing it with Erubis.
    # This is the code helper method used to log out USAGE and README files.
    #
    # === Params
    #  src_path:: the file path for the logger
    #  a_logger:: optional logger to use.  defaults to builtin logger
    #
    # === Returns
    #  self
    #
    def log_file(src_path, a_logger = nil)
      a_logger = self.logger if a_logger.nil?
      if !File.exists?(src_path)
        warn "Could not find #{File.basename(src_path)} in generator source"
      else
        require 'erubis'
        a_logger << Erubis::Eruby.new(File.read(src_path)).result(binding()) 
        a_logger << "\n"
      end
      return self 
    end
    
    # Logs the README file in the source_root if found or logs a warning.
    def log_readme(a_logger=nil)
      src_path = self.source_root / "README"
      log_file(src_path, a_logger)
    end
    
    # Logs the USAGE file in the source_root if found or logs a warning.
    def log_usage(a_logger=nil)
      src_path = self.source_root / 'USAGE'
      log_file(src_path, a_logger)
    end

    ################################################
    ## UTILITY METHODS
    ##    

    # Returns the full namespace and class name if both are defined.
    def namespace_class_name
      [self.namespace, self.class_name].compact.join '.'
    end

    # Returns the full namespace and object name if both are defined.
    def namespace_instance_name
      [self.namespace, self.instance_name].compact.join '.'
    end
    
    # Verifies that the passed array of keys are defined on the object.  If
    # you pass an optional block, the block will be invoked for each key so
    # you can validate the value as well.  Otherwise, this will raise an error
    # if any of the properties are nil.
    def requires!(*properties)
      properties.flatten.each do |key_name|
        value = self.send(key_name)
        is_ok = !value.nil?
        is_ok = yield(key_name, value) if block_given? && is_ok
        unless is_ok
          fatal!("This generator requires a #{Extlib::Inflection.humanize key_name}")
        end
      end
      return self
    end
    
    # Converts a path with optional template variables into a regular path
    # by looking up said variables on the receiver.  Variables in the pathname
    # must appear inside of a pair of {}. (Like the Amazon Search URL spec)
    def expand_path(path)
      path = path.gsub(/\{(.*?)\}/) { self.send($1) || $1 }
      File.expand_path path
    end
    
    # Calls your block for each file and directory in the source template
    # passing the expanded source path and the expanded destination directory
    #
    # Expects you to include a block with the following signature:
    #
    #  block |filename, src_path, dst_path|
    #
    #  filename:: the filename relative to the source directory
    #  src_path:: the full path to the source
    #  dst_path:: the full destination path
    #
    # === Param
    #  source_dir:: optional source directory.  Defaults to templates
    #  build_dir::  optional build directory.  Defaults to build_root
    # === Returns 
    #  self
    #
    def each_template(source_dir = nil, build_dir=nil) 
      source_dir = self.source_root / 'templates' if source_dir.nil?
      build_dir = self.build_root if build_dir.nil?
      
      Dir.glob(source_dir / '**' / '*').each do |src_path|
        filename = src_path.sub(source_dir / '', '')
        dst_path = build_dir / filename
        yield(filename, src_path, dst_path) if block_given?
      end
      return self
    end
    
    # Copies from source to destination, running the contents through ERB
    # if the file appears to be a text file.  The destination file must not
    # exist or else a warning will be logged.
    #
    # === Returns
    #  true if copied successfully.  false otherwise
    #
    def copy_file(src_path, dst_path) 

      # interpolate dst_path to include any variables
      dst_path = expand_path(dst_path)
      
      src_filename = src_path.sub(self.source_root / '', '')
      dst_filename = dst_path.sub(self.build_root / '', '')
      ret = true 

      # if the source path does not exist, just log a warning and return
      if !File.exist? src_path
        warn "Did not copy #{src_filename} because the source does not exist."
        ret = false
        
      # when copying a directory just make the dir if needed
      elsif File.directory?(src_path)
        logger << " ~ Created directory at #{dst_filename}\n" if !File.exist?(dst_path)
        FileUtils.mkdir_p(dst_path) unless self.dry_run
        
      # if destination already exists, just log warning
      elsif File.exist?(dst_path) && !self.force
        warn "Did not overwrite #{dst_filename} because it already exists."
        ret = false
        
      # process file through erubis and copy
      else
        require 'erubis'
        
        input = File.read(src_path)
        eruby = ::Erubis::Eruby.new input
        output = eruby.result(binding())
        
        unless self.dry_run
          file = File.new(dst_path, 'w')
          file.write output
          file.close
        end
        
        logger << " ~ Created file at #{dst_filename}\n"
      end
      return ret 
    end

    # Converts a string to snake case.  This method will accept any variation
    # of camel case or snake case and normalize it into a format that can be
    # converted back and forth to camel case.  
    #
    # === Examples
    # 
    #   snake_case("FooBar")           #=> "foo_bar"
    #   snake_case("HeadlineCNNNews")  #=> "headline_cnn_news"
    #   snake_case("CNN")              #=> "cnn"
    #   snake_case("innerHTML")        #=> "inner_html"
    #   snake_case("Foo_Bar")          #=> "foo_bar"
    #
    # === Params
    #
    #  str:: the string to snake case
    #
    def snake_case(str='') 
      str = str.gsub(/([^A-Z_])([A-Z][^A-Z]?)/,'\1_\2') # most cases
      str = str.gsub(/([^_])([A-Z][^A-Z])/,'\1_\2') # HeadlineCNNNews
      str.downcase
    end
    
    ABBREVIATIONS = %w(html css xml)
    
    # Converts a string to CamelCase.  If you pass false for the second param
    # then the first letter will be lower case rather than upper.  This will
    # first snake_case the passed string.  This version differs from the 
    # standard camel_case provided by extlib by supporting a few standard
    # abbreviations that are always make upper case.
    #
    # === Examples
    #
    #  camel_case("foo_bar")                #=> "FooBar"
    #  camel_case("headline_cnn_news")      #=> "HeadlineCnnNews"
    #  camel_case("html_formatter")     #=> "HTMLFormatter"
    #  
    # === Params
    # 
    #  str:: the string to camel case
    #  capitalize:: capitalize first character if true (def: true)
    #
    def camel_case(str, capitalize=true)
      str = snake_case(str) # normalize
      str.gsub(capitalize ? /(\A|_+)([^_]+)/ : /(_+)([^_]+)/) do 
        ABBREVIATIONS.include?($2) ? $2.upcase : $2.capitalize
      end
    end
    
    protected
    
    # Standardized parsing of arguments.  This will accept an argument that
    # is either a class name or a path name and generate both a class name and
    # a pathname from it.
    #
    def parse_arguments!
      name  = (self.arguments || [])[1]
      parts = name.include?('/') ? name.split('/') : name.split('.')

      # method_name would be extracted from for instance Todos.Task.methodName 
      # for generators that allow it
      if parts[2] && self.method_name.nil?
        self.method_name = camel_case(parts[2], false)
      end

      # target_name is first part snake_cased, unless already defined
      if parts[0] && self.target_name.nil?
        self.target_name = snake_case(parts[0]) 
      end
      
      # namespace is first part CamelCases if defined.  Otherwise use 
      # target_name if defined
      if (parts[0] || self.target_name) && self.namespace.nil?
        self.namespace = camel_case(parts[0] || self.target_name)
      end 

      # filename is second part snake_cased, unless already defined
      if parts[1] && self.filename.nil?
        self.filename = snake_case(parts[1])
      end
      
      # class_name is second part CamcelCased if defined.  Otherwise use 
      # filename if defined.
      if (parts[1] || self.filename) && self.class_name.nil?
        self.class_name = camel_case(parts[1] || self.filename)
      end
      
      # object_name is class name with first letter lower case.  Used in case
      # the template wants to define an instance instead of class.
      if self.class_name && self.instance_name.nil?
        self.instance_name = self.class_name.sub(/^(.)/) { |x| x.downcase }
      end
      
    end
    
  end
  
end