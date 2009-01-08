require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

require 'fileutils'
require 'tempfile'

describe 'build/copy.rake', 'build:copy' do
  
  include Abbot::SpecHelpers

  # get the app1 bundle -- override the build_root config so that it will go
  # to a tmp directory.
  before do
    
    # create a directory to hold builds
    @tmpdir = File.join(Dir.tmpdir, 'test-build-copy', Time.now.to_i.to_s)
    FileUtils.mkdir_p(@tmpdir)
    
    # get a source path --
    @src_path = fixture_path *%w(basic_library apps app1 unlocalized.js)
    @dst_path = File.join(@tmpdir, 'unlocalized.js')
    
    # get buildfile
    @buildfile = abbot_library.buildfile
  end
  
  after do
    FileUtils.rm_r(@tmpdir)
  end
  
  def files_equal?
    src_file = File.exist?(@src_path) ? File.read(@src_path) : ''
    dst_file = File.exist?(@dst_path) ? File.read(@dst_path) : ''
    src_file == dst_file
  end
  
  # Executes the task.  Returnes TRUE if the task was actually invoked, 
  # NO otherwise.
  def exec_task
    @buildfile.execute_task 'build:copy', 
      :src_path => @src_path, :dst_path => @dst_path,
      :src_paths => [@src_path]
  end
  
  it "should copy the source file to the destination if the source exists and destination does not exist" do
    # Verify preconditions
    File.exist?(@src_path).should be_true
    File.exist?(@dst_path).should be_false
    
    exec_task
      
    # Verify copy succeeded...
    File.exist?(@dst_path).should be_true
    files_equal?.should be_true
  end
  
  it "should overwrite the destination if it is older than the source" do

    # write dst file...
    f = File.open(@dst_path, 'w+')
    f.write "OLDER FILE"
    f.close

    make_newer(@src_path, @dst_path)
    
    # Verify precondition
    (File.mtime(@src_path) > File.mtime(@dst_path)).should be_true

    exec_task

    files_equal?.should be_true
  end

  it "should run but do nothing if the source no longer exists" do
    FileUtils.cp @src_path, @dst_path
    old_src= @src_path
    @src_path = "/imaginary/file"
    
    exec_task 
    
    File.exist?(@dst_path).should be_true
    @src_path = old_src
    files_equal?.should be_true
  end
  
  it "should not run if the destination is newer than the source" do
    
    # write new dst_path .. make sure it is newer & different...
    f = File.open(@dst_path, 'w+')
    f.write "NEWER FILE"
    f.close

    make_newer(@dst_path, @src_path)
    
    # run the task
    exec_task
    
    # make sure the task did not overwrite the file.
    File.read(@dst_path).should eql("NEWER FILE")
    
  end
  
end
