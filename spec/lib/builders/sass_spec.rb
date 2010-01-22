require File.join(File.dirname(__FILE__), 'spec_helper')

# If sass is not installed, just skip these.
has_sass = true
begin
  require 'sass'
  
rescue Exception => e
  puts "WARNING: Skipping SC::Builder::Sass tests because sass is not installed.  Run 'sudo gem install haml' first and try again."
  has_sass = false
end

if has_sass
  describe SC::Builder::Sass do
  
    include SC::SpecHelpers
    include SC::BuilderSpecHelper
  
    before do
      std_before :sass_test
      @manifest.add_entry 'icons/image.png'
    end


    after do
      std_after
    end

    def run_builder(filename)
      super do |entry, dst_path|
        SC::Builder::Sass.build(entry, dst_path)
      end
    end
  
    it "should build a sass file" do
      lines = run_builder('sample.sass')
      lines = lines.join('').gsub("\n",'') # strip newlines to make compare easy
    
      # just verify that output looks like the CSS we expect
      lines.should =~ /\#main\s+p.+\{.+color.+width.+\}/
    end
    
    it "converts static_url() and sc_static() => 'url('foo')' " do
      lines = run_builder('sample.sass')
      css = lines.join("\n")
      
      css.should_not =~ /(static_url|sc_static)/
      css.should =~ /url\('.+'\)/ # important MUST have some url...
    end
  end
end