require File.join(File.dirname(__FILE__), 'spec_helper')
describe SC::Builder::CombineJavaScript do
  
  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :combine_javascript
  end

  def run_builder(filename, localize=false)
    super(filename) do |entry, dst_path|
      entry[:localized] = true if localize
      SC::Builder::JavaScript.build(entry, dst_path)
    end
  end
  
end
