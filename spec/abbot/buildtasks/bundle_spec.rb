require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe 'bundle.rake', 'bundle:compute_build_number' do
  
  include Abbot::SpecHelpers


  it "should use the build_number specified in the config, if provided" do
    library = basic_library
    library.buildfile.define { config :all, :build_number => :FOO123 }
    library.bundle_for(:app1).build_number.should  eql(:FOO123)
  end
  
  it "should compute a build_number based on the content of all files in a bundle if no build_number if provided" do
    
    # First, add a tmpfile to app1 that we can modify
    tmpfile = fixture_path *%w(basic_library apps app1 tmpfile.txt)
    f = File.open(tmpfile, "w+")
    f.write("test1")
    f.close
    
    bundle = basic_library.bundle_for(:app1)
    bundle.config.build_number.should be_nil # Verify precondition
    
    # Build number should be computed dynamically --
    first_build_number = bundle.build_number
    first_build_number.should_not be_nil
    first_build_number.size.should_not eql(0)
    
    # Now touch the tmpfile and get build number again.  The build number
    # should not change since the contents have not changed.
    require 'fileutils'
    FileUtils.touch(tmpfile)
    bundle = basic_library.bundle_for(:app1)
    bundle.build_number.should eql(first_build_number)
    
    # Now, edit the tmpfile and get the build number again.  The build number
    # should change since the contents have changed
    f = File.open(tmpfile, "w+")
    f.write("test2")
    f.close

    bundle = basic_library.bundle_for(:app1)
    bundle.build_number.should_not eql(first_build_number)
    
    # Cleanup
    FileUtils.rm(tmpfile)
    
  end
   
end
