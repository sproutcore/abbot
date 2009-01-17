require File.join(File.dirname(__FILE__), 'spec_helper')

describe "build:css" do
  
  include SC::SpecHelpers
  include SC::BuildSpecHelpers
  
  before do
    std_before
    @task_name = 'build:css'
  end
  
  # describe "wraps compiler directives in comments" do
  #   it "sc_require()"
  #   
  #   it "require()"
  #   it "sc_resource()"
  # 
  #   it "does not remove directives inside of comments"
  # end
  # 
  # it "substitutes static_url() and sc_static_url() directives"
  
end
