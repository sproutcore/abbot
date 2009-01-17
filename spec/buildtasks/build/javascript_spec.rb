require File.join(File.dirname(__FILE__), 'spec_helper')

describe "build:javascript" do
  
  include SC::SpecHelpers
  include SC::BuildSpecHelpers
  
  before do
    std_before
    @task_name = 'build:javascript'
  end
  
  # it "should concatenate the input JS files according to their require order"
  # 
  # it "substitutes static_url() and sc_static_url() directives"
  # 
  # it "substitutes sc_super() directives"
  # 
  # it "minifies the Javascript if CONFIG.minify_javascript is true"
  # 
  # it "minifies the Javascript if CONFIG.minify is true"
  # 
  # it "labels the start of each JS file in concatenated result (before minify)"
  
end
