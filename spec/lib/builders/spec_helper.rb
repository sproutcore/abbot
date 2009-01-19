require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

module SC::BuilderSpecHelper
  
  def std_before(target_name)
    @project  = temp_project :builder_tests
    @target   = @project.target_for target_name
    @manifest = @target.manifest_for :language => :en
    @manifest.prepare!
  end
  
  def run_builder(filename, &block)
    @entry = @manifest.add_entry filename # basic entry...
    @dst_path = @entry.build_path
    File.exist?(@entry.source_path).should be_true # precondition
    
    # Invoke builder
    yield(@entry, @dst_path)
    
    lines = File.readlines(@dst_path)
    lines.size.should > 0 # make sure something built
    return lines
  end
  
end
    