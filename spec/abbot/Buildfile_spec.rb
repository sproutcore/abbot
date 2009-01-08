require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe 'Builtin Buildfile', 'bundle_name' do
  
  include Abbot::SpecHelpers

  # note: the basic_library helper should load the a library on the basic
  # library with the abbot root in the search path - simulating the effect
  # of using the build tools once they are installed.
  
  it "should define manifest:build"  do
    basic_library.buildfile.lookup('manifest:build').should_not be_nil
  end

  it "should define bundle:compute_build_number" do
    basic_library.buildfile.lookup('bundle:compute_build_number').should_not be_nil
  end
  
end
