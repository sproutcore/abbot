require "lib/builders/spec_helper"

describe SC::Builder::Handlebars do

  include SC::SpecHelpers
  include SC::BuilderSpecHelper

  before do
    std_before :handlebars_test

    # add fake image entry for sc_static tests..
    @manifest.add_entry 'icons/image.png'
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
    lines = run_builder 'templates/template.handlebars'
    lines[0].should =~ /SC\.TEMPLATES\["template"\] =/
  end

  it "handles sc_static" do
    lines = run_builder 'templates/template.handlebars'
    lines[0].should include('<img src=\\"/static/handlebars_test/en/current/icons/image.png?0\\" />')
  end

end
