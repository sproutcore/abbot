# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  # Generates components for SproutCore. The generator allows the user
  # to quickly set up a SproutCore framework using any of the built in
  # templates such as the project itself, apps, models, views, controllers
  # and more
  #
  # The template files will be copied to their target location and also be
  # parsed through the Erubis templating system. Template file paths can
  # contain instance variables in the form of _class_name_ which in turn would
  # be the value of class_name once generated.
  #
  # To develop a new generator, you can add it to the sproutcore/gen/
  # directory with the following file structure:
  #    gen/
  #      <generator_name>/   - singular directory name of the generator
  #         Buildfile        - contains all config options and build tasks
  #         README           - prints when generator is done
  #         templates/       - contains all the files you want to generate
  #         USAGE            - prints when user gives uses --help option
  #
  class Tools

    no_tasks do
      def show_help(generator_name=nil, generator=nil)
        if generator_name
          if generator.nil?
            warn("There is no #{generator_name} generator")
          else
            generator.log_usage
          end
        else
          SC.logger << "Available generators:\n"
          SC::Generator.installed_generators_for(project).each do |name|
            SC.logger << "  #{name}\n"
          end
          SC.logger << "Type sc-gen GENERATOR --help for specific usage\n\n"
        end
        return 0
      end
    end

    desc "gen generator Namespace[.ClassName] [--target=TARGET_NAME] [--filename=FILE_NAME]",
      "Generates SproutCore components"

    method_options(:help       => :string,
                             :filename   => :string,
                             :target     => :string,
                             '--dry-run' => false,
                             :force      => false,
                             :statechart => false)

    def gen(*arguments)
      return show_help if arguments.empty?

      # backwards compatibility case: client is a synonym for 'app'
      name = arguments[0]=='client' ? 'app' : arguments[0]

      # The --statechart switch uses a different app or project generator
      if name == 'app' && options[:statechart]
        name = 'statechart_app'
      end

      # Load generator
      generator_project = self.project || SC.builtin_project
      generator = generator_project.generator_for name,
        :arguments   => arguments,
        :filename    => options[:filename],
        :target_name => options[:target],
        :dry_run     => options[:"dry-run"],
        :force       => options[:force],
        :statechart  => options[:statechart]

      # if no generator could be found, or if we just asked to show help,
      # just return the help...
      return show_help(name, generator) if generator.nil? || options[:help]

      begin
        # Prepare generator and then log some debug info
        generator.prepare!
        info "Loading generator Buildfile at: #{generator.buildfile.loaded_paths.last}"

        debug "\nSETTINGS"
        generator.each { |k,v| debug("#{k}: #{v}") }

        # Now, run the generator
        generator.build!

      rescue Exception => error_message
        warn "For specific help on how to use this generator, type: sc-gen #{name} --help"
        fatal! error_message.to_s
      end

      SC.logger << "\n"
      generator.log_readme
      return 0
    end

  end
end
