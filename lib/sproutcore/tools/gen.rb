require File.join(SC::LIBPATH, 'sproutcore', 'helpers', 'generator_helper')

module SC
  
  # Generates components for SproutCore. The generator allows the user
  # to quickly set up a SproutCore framework using any of the built in templates
  # such as the project itself, apps, models, views, controllers and more
  # 
  # The template files will be copied to their target location and also be parsed
  # through the Erubis templating system. Template file paths can contain instance 
  # variables in the form of _class_name_ which in turn would be the value of 
  # @class_name once generated.
  # 
  # To develop a new generator, you can add it to the sproutcore/gen/ directory
  # with the following file structure:
  #    gen/
  #      <generator_name>/   - singular directory name of the generator
  #         Buildfile        - contains all configuration options and build tasks
  #         README           - prints when generator is done
  #         templates/       - contains all the files you want to generate
  #         USAGE            - prints when user gives sc-gen <generator_name> --help
  # 
  GENPATH = File.join(SC::LIBPATH, "..", "gen")
  
  class Tools
    include SC::GeneratorHelper
    
    def show_help(generator_name=nil, generator=nil)
      if generator_name
        if generator.nil?
          warn("There is no #{generator_name} generator") 
        else
          log_file(generator.generator_root / 'USAGE')
        end
      else
        SC.logger << "Available generators:\n"
        SC.logger << SC::Generator.installed_generators_for(project)
        SC.logger << "\nType sc-gen GENERATOR --help for specific usage\n"
      end
      return 0
    end
    
    desc "sc-gen generator Namespace[.ClassName] [--target=TARGET_NAME] [--filename=FILE_NAME]", 
      "Generates SproutCore components"
    
    method_options(
      MANIFEST_OPTIONS.merge(:help => :optional,
                             :filename => :optional,
                             :target => :optional))
      
    def gen(*arguments)
      return show_help if arguments.empty?
      
      # backwards compatibility case: client is a synonym for 'app'
      name = arguments[0]=='client' ? 'app' : arguments[0]
      
      # Load generator
      generator_project = self.project || SC.builtin_project
      generator = generator_project.generator_for name,
        :arguments =>   arguments,
        :filename  =>   options[:filename],
        :target_name => options[:target]

      # if no generator could be found, or if we just asked to show help,
      # just return the help...
      return show_help(name, generator) if generator.nil? || options[:help] 
      
      begin
        # Prepare generator and then log some debug info
        generator.prepare!
        info "Loading generator Buildfile at: #{generator.buildfile.path}"
      
        debug "GENERATOR SETTINGS"
        generator.each { |k,v| debug("#{k}: #{v}") }
        
        # Now, run the generator
        generator.build!
        
      rescue Exception => error_message
        warn "For specific help on how to use this generator, type: sc-gen #{name} --help"
        fatal! error_message
      end

      log_file(generator.generator_root / "README")
      return 0
    end
    
    def dummy2
      # Buildfile inclusion
      #  -- NOTE: the generator system uses a custom configuration of 
      #  buildfiles and build rules that is separate from the regular build
      #  system.
      buildfile_location = File.join(SC::GENPATH, @generator, "Buildfile")
      info "Loading generator build file: " + buildfile_location
      
      @buildfile = SC::Buildfile.load(buildfile_location)
      @target_directory = @buildfile.config_for('/templates')[:root_dir]
      
      assign_names!(arguments[1])
      
      if options[:filename]
        # override the file_path with the passed in filename
        @file_path = options[:filename]
      end
      
      replace_with_instance_names!(@target_directory)
      append_to_class_name!
      append_to_file_path!
      
      debug "@namespace: " + @namespace.to_s
      debug "@class_name: " + @class_name.to_s
      debug "@namespace_with_class_name: " + @namespace_with_class_name.to_s
      debug "@method_name: " + @method_name.to_s
      debug "@class_nesting_depth: " + @class_nesting_depth.to_s
      debug "@file_path: " + @file_path.to_s
      debug "@mvc_type: " + @mvc_type.to_s
      debug "base_class_name(): " + base_class_name
      
      if options[:target]
        # prepend the target_directory with whatever is passed as --target
        @custom_target = YES
        @target_directory = options[:target]
      end
      
      begin
        # check all requirements in the Buildfile
        check_requirement_class_nesting_depth
        check_requirement_pwd
        check_requirement_root_dir
      rescue RuntimeError => error_message
        warn "For specific help on how to use this generator, type: sc-gen #{@generator} --help"
        fatal! error_message
      end
      
      info "target_directory: " + @target_directory
      
      # get list of template files to copy
      files = template_files(true, true, generator_dir, true)
      
      # copy files and parse them through Erubis in one swoop
      copy_files(files, @target_directory)

      debug "#{@files_generated} files generated"

      # only print README if files were actually generated
      prints_content_of_file(@generator, 'README') if @files_generated!=0
      
    end
    
  end
end
