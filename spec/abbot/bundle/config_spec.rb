require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'config' do
  
  include Abbot::SpecHelpers

  it "should merge configs for bundle and parent bundles" do
    b = nested_app1_bundle
    env = b.config
    env.should_not be_nil
    
    env[:key1].should eql(:basic_library) # supplied by basic_library - all
    env[:key2].should eql('lib1') # supplied lib1 - all
    env[:key3].should eql('nested_app1') # supplied by nested_app1 - all
  end
  
  it "should merge bundle-specific configs over all configs" do
    b = nested_app1_bundle
    (env = b.config).should_not be_nil
    env[:key4].should eql('nested:basic_library') # supplied by basic_library - app
    env[:key5].should eql('nested:lib1') # supplied by lib1 - app
    env[:key6].should eql('nested:nested_app1') # supplied by nested_app1 - app
  end
  
  it "should merge environment-specific options over all configs" do
    Abbot.env[:build_number] = 123
    b = nested_app1_bundle
    (env = b.config).should_not be_nil
    env[:build_number].should eql(123) # from specific opts
  end
  
  it "should merge build mode specific configs" do
    old_build_mode = Abbot.env[:build_mode]
    Abbot.env[:build_mode] = :production
    
    b = nested_app1_bundle # create new bundle with setting..
    b.config[:is_production].should eql(true) # supplied by basic_library/config
  end
    
  it "should merge in global config settings from other libraries (but not from bundles within the libraries)" do
    # buid library 
    lib = basic_library
    b = lib.bundle_for(:lib1)
    
    # supplied in installed_library/sc-config
    b.config[:installed_key].should eql(:installed_library)
    
    # defined in installed_library/frameworks/installed_lib1/sc-config
    b.config[:installed_lib1].should_not eql(true)
  end
    
end