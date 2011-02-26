require "lib/builders/spec_helper"

describe SC::Builder::Handlebars do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :handlebars_test
  end

  after do
    std_after
  end

  def run_builder(filename)
    super do |entry, dst_path|
      SC::Builder::Handlebars.build(entry, dst_path)
    end
  end

  it "converts Handlebars to JavaScript" do
    lines = run_builder 'template.handlebars'
    lines.each do |line|
      line.should =~ /SC\.TEMPLATES/
    end
  end

end
