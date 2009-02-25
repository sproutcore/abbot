# extlib has built in under_case and camel_case string methods
require 'extlib'

module SC

  # You can use these methods to copy the contents of your templates
  # directory into a target location.
  module GeneratorHelper

    def copy_files(files, destination)
      require 'erubis'

      files.each do |x|
        dest = destination + "/" + x.gsub(/(.*\/templates\/)/, '')
        copy(x, dest)
      end
    end
    
    def replace_with_instance_names!(string_to_replace)
      # set up which instance names we will be looking for and replacing
      # used in templates/ file_structure to replace file locations with the instance names
      # these instance names must be entered with an underscore before and after (for instance _file_path_ )
      instance_names = %w(file_path class_path target_name language_name class_name method_name subclass_name subclass_nameplural mvc_name)
        
      instance_names.each do |x|
        instance_name = "_#{x}_"
        if string_to_replace.include? instance_name
          instance_string_value = instance_variable_get("@#{x}").to_s
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
        next if @generator=='test' && @method_name && x=='_subclass_name_.js'
        next if @generator=='test' && !@method_name && x=='_subclass_name_'

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
      
      replace_with_instance_names!(to)
      # if to still contains unfilled instance placeholders ignore this file
      if to.rindex(/\_.*?\_/)!=nil
        debug "Ignored #{from} as it was #{to}"
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

        SC.logger << " ~ Copied file #{from.sub(/^#{Regexp.escape SC::GENPATH}/,'')} to #{to}\n"
      end
    end
    
    def puts_content_of_file(template, type)
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
        @class_name = @class_name + append_string unless class_name.include?(append_string)
      end
    end

    # Convert the Ruby version of the class name to a JavaScript version.
    def client_class_name
      @class_name
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

      if root_dir_requirement && root_dir_requirement==YES && !File.directory?(@target_root)
        root_dir_requirement_message = @buildfile.config_for('/templates')[:required_root_dir_message]
        raise "The directory #{@target_root} is missing. #{root_dir_requirement_message}"
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
        
        if @target_root[0,1]!='/' 
          required_pwd.each do |x|
            if File.directory?(x) 
              @target_root = File.join(x, @target_root)
              info "Found possible target location at #{@target_root}. For more precision use --target"
              found_dir = YES
              break
            end
            
            if File.directory?(File.join('..', x))
              @target_root = File.join(File.join('..', x), @target_root)
              info "Found possible target location at #{@target_root}. For more precision use --target"
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
      @class_nesting || default_base_class_name
    end

    # Checks whether the proper file structure exists to generate files
    def file_structure_exists?
      has_path_and_filename? && target_directory_exists?
    end
    
    # Checks whether the target directory for a generated file exists
    def target_directory_exists?
      File.exists?("#{Dir.pwd}/clients/#{File.dirname(args[0])}")
    end
    
    # Checks that file generation was in the format client_name/file_name
    def has_path_and_filename?
      !(File.dirname(args[0]) == '.')
    end
    
    def mvc_name
      if @name.include?('Controller') 
        return 'controllers'
      elsif @name.include?('View') 
        return 'views'
      else 
        return 'models'
      end
    end
        
    ###################
    # Borrowed from Rails NamedBase

    attr_reader   :name, :class_name, :subclass_name
    attr_reader   :class_path, :file_path, :class_nesting, :class_nesting_depth

    def assign_names!(name)
      
      @name = name
      base_name, @class_path, @file_path, @class_nesting, @method_name, @class_nesting_depth = extract_modules(@name)
      @class_name_without_nesting = inflect_names(base_name)
      
      @subclass_name = @class_name_without_nesting.snake_case
      # TODO: make this is an intelligent pluralizer
      @subclass_nameplural = @class_name_without_nesting.snake_case + 's'
      # used for determining test location
      @mvc_name = mvc_name
      
      if @class_nesting.empty?
        @class_name = @class_name_without_nesting
      else
        @class_name = "#{@class_nesting}.#{@class_name_without_nesting}"
      end
    end
    
    def strip_name(name) 
      return name.gsub('Controller', '').gsub('View', '')
    end

    # Extract modules from filesystem-style or ruby-style path:
    #   good/fun/stuff
    #   Good::Fun::Stuff
    # produce the same results.
    def extract_modules(name)
      modules       = name.include?('/') ? name.split('/') : name.split('.')
      base_name     = modules[1] ? modules[1] : name
      method_name   = modules[2]
      modules.pop

      class_path    = modules.first ? modules.first.snake_case : name.snake_case
      stripped_name = strip_name(name)
      file_path     = class_path
      class_nesting = modules.map { |m| m.camel_case }.join('.')
      
      [base_name, class_path, file_path, class_nesting, method_name, modules.size]
    end

    def inflect_names(name)
      name = strip_name(name)
      camel  = name.camel_case
      under  = camel.snake_case
      camel
    end

  end
end
