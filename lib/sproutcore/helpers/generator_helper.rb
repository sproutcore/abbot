# extlib has built in under_case and camel_case string methods
require 'extlib'

module SC

  # You can use these methods to copy the contents of your templates
  # directory into a target location.
  module GeneratorHelper

    attr_reader :class_name, :namespace, :file_path, :method_name, :namespace_with_class_name

    # Parses the first argument given in the command line and set the 
    # necessary instance variables
    #
    # === Params
    #  name:: string of passed in argument from cli (for instance Todos.Task)
    def assign_names!(name)
      # @name_as_passed is the appname/classname combination and should never be changed 
      @name_as_passed = name.freeze
      @file_path, @namespace, @class_name, @method_name, @class_nesting_depth = extract_modules(@name_as_passed)

      @mvc_type = mvc_type if @generator=='test'
      
      if @namespace.empty?
        @namespace_with_class_name = @class_name
      else
        @namespace_with_class_name = "#{@namespace}.#{@class_name}"
      end
    end
    
    # Will strip out Controller or View from the class name
    # TODO: move to Controller/View Buildfile as task?
    #
    # === Params
    #  name:: string of class name (for instance Task in Todos.Task)
    #
    # === Returns
    #  The stripped down string
    def strip_name(name) 
      return name.snake_case.downcase.gsub('controller', '').gsub('view', '')
    end

    # Extract modules from filesystem-style or JavaScript-style path:
    # todos/task and Todos.Task - will produce the same results
    #
    # === Params
    #  name:: string of passed in first argument from cli (for instance 
    #    Todos.Task)
    #
    # === Returns
    #  An array of components derived from the string
    def extract_modules(name)
      modules       = name.include?('/') ? name.split('/') : name.split('.')
      class_name    = strip_name(modules[1] ? modules[1] : name).camel_case
      # method_name would be extracted from for instance Todos.Task.methodName for generators that allow it
      method_name   = modules[2] ? Extlib::Inflection.camelize(modules[2], false) : nil
      modules.pop
      
      # file_path will be overridden if --filename is specified
      # if there is no class_name, use @name_as_passed
      file_path     = modules.first ? modules.first.snake_case : name.snake_case
      namespace     = modules.map { |m| m.camel_case }.join('.')
      
      [file_path, namespace, class_name, method_name, modules.size]
    end

    # Will copy files from one location to another and strip out anything
    # that precedes and includes /templates in the destination path
    #
    # === Params
    #  files:: array containing file paths to copy
    #  destination:: string of where to copy the files to
    def copy_files(files, destination)
      require 'erubis'
      files.each do |x|
        dest = destination + "/" + x.gsub(/(.*\/templates\/)/, '')
        copy(x, dest)
      end
    end

    # Will look if a string contains any of the predefined instance variable 
    # names and replace them with their values. This is mostly used for 
    # templates/ file_structure.  These instance names must be entered with an 
    # underscore before and after (for instance _file_path_ )
    #
    # === Params
    #  string_to_replace:: string that might contain instance variables to 
    #    replace
    #  destination:: boolean to make the instance variable snake_case . 
    #    default YES
    #  
    # === Returns
    #  The string replaced with the instance variable value(s)
    def replace_with_instance_names!(string_to_replace, snake_case=YES)
      
      instance_names = %w(file_path target_name language_name namespace_with_class_name method_name class_name mvc_type)
      
      instance_names.each do |x|
        instance_name = "_#{x}_"
        if string_to_replace.include? instance_name
          instance_string_value = instance_variable_get("@#{x}").to_s
          instance_string_value = instance_string_value.snake_case if snake_case
          if instance_string_value!=''
            string_to_replace.gsub!(instance_name, instance_string_value)
          end
        end
      end
      
      string_to_replace
    end

    # Finds a list of available generators (based on templates/ directory)
    #
    # === Returns
    #  An array containing the strings of all available generators
    def generators
      template_files(true, false, SC::GENPATH, false)
    end
    
    # Creates a list of all files and directories inside a given directory
    #
    # === Params
    #  directories:: boolean to include directories or not
    #  sub_directories:: boolean to include sub directories
    #  cur_dir:: string with path of where to start
    #  directories:: boolean to include full gen path or not
    #  
    # === Returns
    #  An array containing path strings of template files
    def template_files(directories=false, sub_directories=false, cur_dir=nil, include_base=false)

      ret = []
      Dir.foreach(cur_dir) do |x|
        next if (x == '.' || x == '..' || x == '.svn' || x[0,1]=='.')

        # UGLY warning: special hard coded rule for test template - ignore if method_name is not specified
        # TODO: move to Buildfile as task?
        next if @generator=='test' && @method_name && x=='_class_name_.js'
        next if @generator=='test' && !@method_name && x=='_class_name_'

        dir = File.join(cur_dir,x)
        add_dir = (include_base ? dir : dir.gsub(SC::GENPATH + "/", ""))
        
        if File.directory?(dir)
          ret << add_dir + '/' if directories
          ret += template_files(directories, sub_directories, dir, include_base) if sub_directories
        else
          ret << add_dir
        end
      end
      
      return ret
    end

    # Builds all directories up to the path given
    #
    # === Params
    #  path:: the directory path that you need constructed
    def build_directories(path)
      parts = path.split('/')
      cpath = []
      parts.each do |p|
        cpath << p
        next if p==nil || p==''
        if !File.directory?(File.join(cpath))
          FileUtils.mkdir_p File.join(cpath)
          info "Created directory #{File.join(cpath)}"
        end
      end
    end
  
    # Copies a specific file from one location to another
    # Before writing copy to disk, it will pass through Erubis
    #
    # === Params
    #  from:: string of path to copy from
    #  to:: string of path to copy to
    def copy(from, to)
      replace_with_instance_names!(to, YES)
      # if to still contains unfilled instance placeholders ignore this file
      if to.rindex(/\_.*?[^\/]\_/)!=nil
        debug "Ignored #{from} since #{to} still contains placeholder(s)"
        return
      end
      
      # Create any parent directories
      dirname = to =~ /\/$/ ? to : File.dirname(to)
      FileUtils.mkdir_p dirname

      if File.exist?(to) && !File.directory?(to)
        warn "File already exists at #{to} -- skipping"
      elsif !File.directory?(from)
        # copy file by reading file contents, parse it through Erubis
        # and then write it to the destination
        input = File.read(from)
        eruby = ::Erubis::Eruby.new(input)
        
        file = File.new(to, "w")
        file.write eruby.result(binding())

        debug "Copied file #{from.sub(/^#{Regexp.escape SC::GENPATH}/,'')} to #{to}"
        SC.logger << " ~ Created #{to}\n"
      end
    end

    # Will output a given file to SC.logger (typically to stdout)
    #
    # === Params
    #  generator:: string of which generator to look in
    #  type:: string of file name to use (typically README or USAGE)
    def prints_content_of_file(generator, type)
      file_location = File.join(SC::GENPATH, generator, type)
      if !File.exists?(file_location) 
        fatal! "Could not find #{type} file at #{file_location}"
      end
      file_text = File.read(file_location)
      SC.logger << file_text
      SC.logger << "\n"
    end

    # Will append a string to @namespace_with_class_name if one is given in 
    # the :class_name_append Buildfile config (typically Controller or View)
    # Will not append if user has already specified the appended string
    def append_to_class_name!
      append_string = @buildfile.config_for('/templates')[:class_name_append]
      if(append_string)
        @namespace_with_class_name = @namespace_with_class_name + append_string unless @class_name.include?(append_string)
      end
    end
    
    # Will append a string to @file_path if one is given in the
    # :file_path_append Buildfile config (typically Language)
    # Will not append if user has already specified the appended string
    def append_to_file_path!
      append_string = @buildfile.config_for('/templates')[:file_path_append]
      if(append_string)
        @file_path = @file_path + append_string unless @file_path.include?(append_string)
        # TODO: this should be moved to Language Buildfile as a task and/or config
        @target_directory = '.'
      end
    end
    
    # Checks if there is a :required_class_nesting_depth config in Buildfile
    # that will require a certain nesting depth
    # Example: mvc generators require nesting depth of one (for instance Todos.Task)
    def check_requirement_class_nesting_depth
      # check if there is a nesting requirement (typically for mvc generators)
      nesting_requirement = @buildfile.config_for('/templates')[:required_class_nesting_depth]
      
      if nesting_requirement && @class_nesting_depth.to_i!=nesting_requirement.to_i
        raise 'You need to specify both the application name and class name'
      end
    end
    
    # Checks if there is a :required_root_dir config in Buildfile
    # that will require a certain root dir to be present
    # Example: mvc generators require the presence of an apps directory
    def check_requirement_root_dir
      root_dir_requirement = @buildfile.config_for('/templates')[:required_root_dir]

      if root_dir_requirement && root_dir_requirement==YES && !File.directory?(@target_directory)
        root_dir_requirement_message = @buildfile.config_for('/templates')[:required_root_dir_message]
        raise "The directory #{@target_directory} is missing. #{root_dir_requirement_message}"
      end
    end
    
    # Checks if there is a :required_pwd config in Buildfile
    # that will require the user to be in a specific working directory
    # Even if we are not in the required pwd, this method will still try to:
    # - check if we can find the required_pwd in the pwd or go up one level to 
    #   find it
    # - only do this check if we are operating on a relative path
    def check_requirement_pwd
      # look up the :required_pwd config array
      required_pwd = @buildfile.config_for('/templates')[:required_pwd]
      current_pwd = Dir.pwd.split('/')[-1]
      
      if required_pwd && !required_pwd.include?(current_pwd) && @custom_target==nil
        found_dir = NO
        
        if @target_directory[0,1]!='/' 
          required_pwd.each do |x|
            if File.directory?(x) 
              @target_directory = File.join(x, @target_directory)
              info "Found possible target location at #{@target_directory}. For more precision use --target"
              found_dir = YES
              break
            end
            
            if File.directory?(File.join('..', x))
              @target_directory = File.join(File.join('..', x), @target_directory)
              info "Found possible target location at #{@target_directory}. For more precision use --target"
              found_dir = YES
              break
            end
            
          end
        end
        
        if !found_dir
          fatal! "The current directory '#{current_pwd}' is not a required present working directory: '#{required_pwd.join('\' or \'')}'."
        end
        
      end
    end

    # Returns the base class name, which is the first argument or a default.
    # === Returns
    #  @namespace or if not present typically SC.Object
    def base_class_name(default_base_class_name = 'SC.Object')
      @namespace || default_base_class_name
    end
        
    # Determines test location for the test generator
    # TODO: move to Buildfile as task?
    # === Returns
    #  models, views or controllers depending on the first cli argument passed
    def mvc_type
       if @name_as_passed.downcase.include?('controller') 
        return 'controllers'
      elsif @name_as_passed.downcase.include?('view') 
        return 'views'
      else 
        return 'models'
      end
    end

  end
end
