require File.join(File.dirname(__FILE__), 'spec_helper')

describe "build:css" do
  
  include SC::SpecHelpers
  include SC::BuildSpecHelpers
  
  before do
    std_before
    @task_name = 'build:css'
  end
  
  it "should concatenate the input css files according to their require order"
  
  describe "remove compiler directives" do
    it "removes sc_require() statments"
    it "removes require() statements"
    it "removes sc_resurce() statements"
    
    it "does not remove directives inside of comments"
    
    it "does not remove directives inside of quoted strings"
  end
  
  it "substitutes static_url() and sc_static_url() directives"
  
  it "minifies the css if CONFIG.minify_css is true"

  it "minifies the css if CONFIG.minify is true"
  
  it "labels the start of each CSS file in concatenated result"
  
end
