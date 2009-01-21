require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

module SC::BuildSpecHelpers
  
  def std_before
    @project = temp_project :real_world
    @target = @project.target_for :sproutcore
    @buildfile = @target.buildfile
    @manifest = @target.manifest_for(:language => :fr)
    
    @target.prepare! # make sure its ready for the manifest...
    @manifest.build! # get a basic manifest good to go...
  end
  
  def std_after
    @project.cleanup
  end
  
  def run_task(entry=nil, dst_path=nil)
    entry ||= @entry
    @buildfile.invoke @task_name,
      :entry => entry,
      :manifest => @manifest,
      :target => @target,
      :config => @target.config,
      :project => @project,
      :src_path => @src_path || entry.source_path,
      :src_paths => @src_path.nil? ? entry.source_paths : [@src_path],
      :dst_path => dst_path || @dst_path || entry.build_path
  end

  def entry_for(filename)
    @manifest.entry_for filename, :hidden => true
  end

end
