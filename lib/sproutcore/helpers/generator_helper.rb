# extlib has built in under_case and camel_case string methods
require 'extlib'

module SC

  # You can use these methods to copy the contents of your templates
  # directory into a target location.
  module GeneratorHelper

    # parse the first argument given in the command line and set the necessary instance variables
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
    
    # TODO: move to Controller/View Buildfile as task?
    def strip_name(name) 
      return name.downcase.gsub('controller', '').gsub('view', '')
    end

    # Extract modules from filesystem-style or JavaScript-style path:
    #   todos/task
    #   Todos.Task
    # produce the same results.
    
    def extract_modules(name)
      modules       = name.include?('/') ? name.split('/') : name.split('.')
      class_name    = strip_name(modules[1] ? modules[1] : name).camel_case
      # method_name would be extracted from for instance Todos.Task.methodName for generators that allow it
      method_name   = modules[2]
      modules.pop
      
      # file_path will be overridden if --filename is specified
      # if there is no class_name, use @name_as_passed
      file_path     = modules.first ? modules.first.snake_case : name.snake_case
      namespace     = modules.map { |m| m.camel_case }.join('.')
      
      [file_path, namespace, class_name, method_name, modules.size]
    end

    def copy_files(files, destination)
      require 'erubis'

      files.each do |x|
        dest = destination + "/" + x.gsub(/(.*\/templates\/)/, '')
        copy(x, dest)
      end
    end
    
    def replace_with_instance_names!(string_to_replace, snake_case=YES)
      # set up which instance names we will be looking for and replacing
      # used in templates/ file_structure to replace file locations with the instance names
      # these instance names must be entered with an underscore before and after (for instance _file_path_ )
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

    def generators
      template_files(true, false, SC::GENPATH, false)
    end

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
    
    def prints_content_of_file(template, type)
      file_location = File.join(SC::GENPATH, template, type)
      if !File.exists?(file_location) 
        fatal! "Could not find #{type} file at #{file_location}"
      end
      file_text = File.read(file_location)
      SC.logger << file_text
      SC.logger << "\n"
    end

    def append_to_class_name!
      append_string = @buildfile.config_for('/templates')[:class_name_append]
      if(append_string)
        @namespace_with_class_name = @namespace_with_class_name + append_string unless @class_name.include?(append_string)
      end
    end
    
    # requirements as defined in the Buildfile for each template
    
    def check_requirement_class_nesting_depth
      # check if there is a nesting requirement (typically for mvc generators)
      nesting_requirement = @buildfile.config_for('/templates')[:required_class_nesting_depth]
      
      if nesting_requirement && @class_nesting_depth.to_i!=nesting_requirement.to_i
        raise 'You need to specify both the application name and class name'
      end
    end
    
    def check_requirement_root_dir
      # check if there is a root_dir requirement (typically for mvc templates)
      root_dir_requirement = @buildfile.config_for('/templates')[:required_root_dir]

      if root_dir_requirement && root_dir_requirement==YES && !File.directory?(@target_directory)
        root_dir_requirement_message = @buildfile.config_for('/templates')[:required_root_dir_message]
        raise "The directory #{@target_directory} is missing. #{root_dir_requirement_message}"
      end
    end
    
    def check_requirement_pwd
      # check if there is a required pwd
      required_pwd = @buildfile.config_for('/templates')[:required_pwd]
      current_pwd = Dir.pwd.split('/')[-1]
      
      if required_pwd && !required_pwd.include?(current_pwd) && @custom_target==nil
        # before raising an error:
        # - check if we can find the required_pwd in the pwd or go up one level to find it
        # - only do this check if we are operating on a relative path
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
    def base_class_name(default_base_class_name = 'SC.Object')
      @namespace || default_base_class_name
    end
    
    # used for determining test location for the test generator
    # TODO: move to Buildfile as task?
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
