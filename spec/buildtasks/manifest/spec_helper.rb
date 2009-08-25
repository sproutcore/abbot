require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

module SC::ManifestSpecHelpers

  def std_before(project_name = :real_world, target_name = :sproutcore)
    @project = fixture_project project_name
    @target = @project.target_for target_name
    @buildfile = @target.buildfile
    @config = @target.config
    @manifest = @target.manifest_for(:language => :fr)
    
    @target.prepare! # make sure its ready for the manifest...
  end

  def run_task(task_name)
    @buildfile.invoke task_name,
      :manifest => @manifest,
      :target =>   @target, 
      :project =>  @project, 
      :config =>   @config
  end

  def entry_for(filename, opts={})
    @manifest.entry_for(filename, opts) || @manifest.entry_for(filename, opts.merge(:hidden => true))
  end
  
  # Verifies that the named task runs when the passed block is executed
  def should_run(task_name, &block)
    task = @buildfile.lookup(task_name)
    first_count = task.invoke_count
    yield if block_given?
    task.invoke_count.should > first_count
  end
  
end
