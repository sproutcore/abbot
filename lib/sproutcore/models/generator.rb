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
    
    # the root path of the generator source
    #attr_reader :generator_root
    
    # the name of the generator
    #attr_reader :generator_name

    # the target project to build in or nil if no target provided
    attr_reader :target_project

    # Creates a new generator.  Expects you to pass at least a generator name
    # and additional options.
    #
    # When you create a generator instance, the object will look for a 
    # directory named "sc_generators/generator_name" or 
    # "generators/generator_name" in a target project. You can pass the
    # project the generator should search if you want.  If you do not pass a
    # target project, the generator will look in the target project instead.
    #
    # If the generator is not found in the target project, it will look in any
    # parent projects as well, usually ending in the builtin project anyway.
    #
    def initialize(generator_name, opts = {})
      @target_project = opts[:target_project]
      self[:generator_name] = generator_name
      @buildfile = nil

      # Find the root path for this generator and all of its assets.
      project = @target_project || SC.builtin_project
      until project.nil?
        'generators sc_generators gen'.each do |dirname|
          generator_root = File.join(project.project_root, dirname, generator_name)
          break if File.directory?(generator_root)
          generator_root = nil
        end
        project = project.parent_project
      end
      if generator_root.nil?
        raise "Could not find generator named: #{generator_name}"
      else
        self.generator_root = generator_root
      end
      
      # Process other options
      self.arguments = opts[:arguments]
      self.target_name = opts[:target_name]
      self.filename = opts[:filename]
      
    end
    
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
      path = File.join(generator_root, 'Buildfile')
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
    
    def prepare!
      return self if @is_prepared
      @is_prepared = true
      
      # Perform standard processing...
      
      # Execute build task
      buildfile.invoke 'generator:prepare'
      
      return self
    end
    
  end
  
end