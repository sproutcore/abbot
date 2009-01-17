require File.join(File.dirname(__FILE__), 'spec_helper')

describe "build:html" do
  
  include SC::SpecHelpers
  include SC::BuildSpecHelpers
  
  before do
    std_before
    @task_name = 'build:html'
  end
  
  it "sets up a shared HtmlContext and invokes the render_task for each entry"
  
  it "finally renders the layout specified in MANIFEST.layout_path"
  
  it "substitutes static_url() directives"
  
  it "supports common text helpers in context"  
  
end
