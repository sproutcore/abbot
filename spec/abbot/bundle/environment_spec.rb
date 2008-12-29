require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'environment' do
  
  include Abbot::SpecHelpers

  it "should merge configs for bundle and parent bundles" do
    b = nested_app1_bundle
    env = b.environment
    env.should_not be_nil
    
    env[:key1].should eql('basic_library') # supplied by basic_library - all
    env[:key2].should eql('lib1') # supplied lib1 - all
    env[:key3].should eql('nested_app1') # supplied by nested_app1 - all
  end
  
  it "should merge bundle-specific configs over all configs" do
    b = nested_app1_bundle
    (env = b.environment).should_not be_nil
    env[:key4].should eql('nested:basic_library') # supplied by basic_library - app
    env[:key5].should eql('nested:lib1') # supplied by lib1 - app
    env[:key6].should eql('nested:nested_app1') # supplied by nested_app1 - app
  end
  
  it "should merge environment-specific options over all configs" do
    Abbot.env[:build_number] = 123
    b = nested_app1_bundle
    (env = b.environment).should_not be_nil
    env[:build_number].should eql(123) # from specific opts
  end
    
    
end