require File.join(File.dirname(__FILE__), 'spec_helper')

# If less is not installed, just skip these.
has_less = true
begin
  require 'less'
  
rescue Exception => e
  puts "WARNING: Skipping SC::Builder::Less tests because less is not installed.  Run 'sudo gem install less' first and try again."
  has_less = false
end

if has_less
  describe SC::Builder::Less do
  
    include SC::SpecHelpers
    include SC::BuilderSpecHelper
  
    before do
      std_before :less_test
      @manifest.add_entry 'icons/image.png'
    end


    after do
      std_after
    end

    def run_builder(filename)
      super do |entry, dst_path|
        SC::Builder::Less.build(entry, dst_path)
      end
    end
  
    it "should build a less file" do
      lines = run_builder('sample.less')
      lines = lines.join('').gsub("\n",'') # strip newlines to make compare easy
    
      # just verify that output looks like the CSS we expect
      lines.should =~ /\#main\s+p.+\{.+color.+width.+\}/
    end
    
    it "converts static_url() and sc_static() => 'url('foo')' " do
      lines = run_builder('sample.less')
      css = lines.join("\n")
      
      css.should_not =~ /(static_url|sc_static)/
      css.should =~ /url\('.+'\)/ # important MUST have some url...
    end
  end
end