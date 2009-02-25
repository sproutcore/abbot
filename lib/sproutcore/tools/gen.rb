require File.join(SC::LIBPATH, 'sproutcore', 'helpers', 'generator_helper')

module SC
  
  GENPATH = File.join(SC::LIBPATH, "..", "gen")
  
  class Tools
    
    include SC::GeneratorHelper
    
    desc "sc-gen generator Namespace[.ClassName] [--target=TARGET_NAME] [--filename=FILE_NAME]", 
      "Generates SproutCore components"
    
    method_options(
      MANIFEST_OPTIONS.merge(:help => :optional,
                             :filename => :optional,
                             :target => :optional))
      
    def gen(*arguments)
      
      if arguments.empty?
        puts "sc-gen generator Namespace[.ClassName] [--target=TARGET_NAME] [--filename=FILE_NAME]"
        if options[:help]
          # show all installed generators
          puts "Available generators:\t\n\t#{generators.join("\n\t").gsub(/\//, '') }"
          puts "Type sc-gen generator --help for specific generator usage"
        end
        return
      end
      
      @generator = arguments[0]=='client' ? 'app' : arguments[0]
      generator_dir = File.join(SC::GENPATH, @generator, 'templates')
      
      if !File.exists?(generator_dir)
        puts "There is no #{@generator} generator"
        puts "Available generators:\t\n\t#{generators.join("\n\t").gsub(/\//, '') }"
        return
      end
      
      if options[:help] 
        puts_content_of_file(@generator, 'USAGE')
        return
      end
      
      # Buildfile inclusion
      buildfile_location = File.join(SC::GENPATH, @generator, "Buildfile")
      info "Loading build file: " + buildfile_location
      
      @buildfile = SC::Buildfile.load(buildfile_location)
      @target_root = @buildfile.config_for('/templates')[:root_dir]
      
      class_name_append = @buildfile.config_for('/templates')[:class_name_append].to_s
      assign_names!(arguments[1])
      
      if options[:filename]
        # override the file_path with the passed in filename
        @file_path = options[:filename]
      end
      
      replace_with_instance_names!(@target_root)
      append_to_class_name!
      
      debug "@class_name: " + @class_name.to_s
      debug "@subclass_name: " + @subclass_name.to_s
      debug "@subclass_nameplural: " + @subclass_nameplural.to_s
      debug "@mvc_name: " + @mvc_name.to_s
      debug "@class_path: " + @class_path.to_s
      debug "@file_path: " + @file_path.to_s
      debug "@class_nesting: " + @class_nesting.to_s
      debug "@class_nesting_depth: " + @class_nesting_depth.to_s
      debug "@class_name_without_nesting: " + @class_name_without_nesting.to_s
      debug "base_class_name: " + base_class_name
      
      if options[:target] && @generator!='project'
        # prepend the target_root with whatever is passed as --target
        @custom_target = YES
        @target_root = options[:target]
      end
      
      begin
        # check all requirements in the Buildfile
        check_requirement_class_nesting_depth
        check_requirement_pwd
        check_requirement_root_dir
      rescue RuntimeError => error_message
        puts error_message
        puts "For specific help on how to use this generator, type: sc-gen #{@generator} --help"
        return
      end
      
      info "Target root: " + @target_root
      # get list of template files to copy
      files = template_files(true, true, generator_dir, true)
      
      # copy files and parse them through Erubis in one swoop
      copy_files(files, @target_root)

      puts_content_of_file(@generator, 'README')
      
    end
    
  end
end
