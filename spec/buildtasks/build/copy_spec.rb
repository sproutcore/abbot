require File.join(File.dirname(__FILE__), 'spec_helper')

describe "build:copy" do
  
  include SC::SpecHelpers
  include SC::BuildSpecHelpers
  
  before do
    std_before
    @task_name = 'build:copy'

    @entry = @manifest.entry_for('demo.html')
    @src_path = @entry.source_path
    @dst_path = @entry.build_path
    
    @entry.build_task.should == 'build:copy' # precondition
  end

  it "copies from source to dst_path if dst_path does not exist" do
    File.exist?(@dst_path).should be_false # precondition
    
    run_task @entry, @dst_path
    files_eql(@src_path, @dst_path).should be_true
  end
  
  it "does not run if newer file exists at dst_path" do
    write_dummy(@dst_path)
    make_newer(@dst_path, @src_path)
    
    run_task
    
    is_dummy(@dst_path).should be_true # make sure task did not copy
  end

  it "replaces dst_path if older file exists at dst_path" do
    write_dummy(@dst_path)
    make_newer(@src_path, @dst_path)
    
    run_task
    
    is_dummy(@dst_path).should be_false # should overrwite older file
    files_eql(@src_path, @dst_path).should be_true
  end
  
  it "does not run if dst_path == src_path" do
    task = @buildfile.lookup('build:copy')
    expected_count = task.execute_count
    
    @dst_path = @src_path
    run_task
    
    task.execute_count.should == expected_count # did not execute!
  end
  
  
end
