# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC
  class Tools

    desc "init PROJECT [APP]",
      "Generates a SproutCore project with an initial application"
    method_options('--dry-run' => false, :force => false, '--template' => false, '--states' => false)
    def init(project_name, app_name=nil)
      
      if project_type = options[:template]
        puts "template"
        project_type = options[:template] ? 'html_project' : 'project' 
      elsif project_type = options[:states] 
        puts "states"
        project_type = options[:states] ? 'project' : 'project'
      else project_type = options[:dry_run] 
        puts "normal"  
        project_type = options[:dry_run] ? 'project' : 'project' 
      end
        

    # Generate the project
     project_gen = SC.builtin_project.generator_for project_type,
      :arguments => ['project', project_name],
      :dry_run   => options['dry-run'],
      :force     => options[:force]
     
     project_gen.prepare!.build!
      
      # Next, get the project root & app name
      project_root = project_gen.build_root / project_gen.filename
      app_name = project_gen.filename if app_name.nil?
      
      # And get the app generator and run it
      project = SC::Project.load project_root, :parent => SC.builtin_project
   
      if project_type = options[:template]
        puts "template_app"
        app_type = options[:template] ? 'html_app' : 'app'
      elsif project_type = options[:states] 
        puts "states_app"
        app_type = options[:states] ? 'states_app' : 'app'
      else project_type = options[:dry_run] 
        puts "nomal_app"
        app_type = options[:dry_run] ? 'app' : 'app'
      end
   
      generator = project.generator_for app_type,
        :arguments => ['app', app_name],
        :dry_run   => options['dry-run'],
        :force     => options[:force]
      generator.prepare!.build!
      
      project_gen.log_file(project_gen.source_root / 'INIT')
      return 0
    end

  end
end
