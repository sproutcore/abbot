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
    method_options('--dry-run' => false, :force => false, '--statechart' => false)
    def init(project_name, app_name=nil)

    # Generate the project
     project_gen = SC.builtin_project.generator_for 'project',
      :arguments => ['project', project_name],
      :dry_run   => options[:"dry-run"],
      :force     => options[:force]

     project_gen.prepare!.build!

      # Next, get the project root & app name
      project_root = project_gen.build_root / project_gen.filename
      app_name = project_gen.filename if app_name.nil?

      # And get the app generator and run it
      project = SC::Project.load project_root, :parent => SC.builtin_project

      # Use the statechart_app generator if --statechart is provided
      app_type = options[:statechart] ? 'statechart_app' : 'app'

      generator = project.generator_for app_type,
        :arguments => ['app', app_name],
        :dry_run   => options[:"dry-run"],
        :force     => options[:force]
      generator.prepare!.build!

      project_gen.log_file(project_gen.source_root / 'INIT')
      return 0
    end

  end
end
