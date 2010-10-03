require "lib/builders/spec_helper"

# If sass is not installed, just skip these.
has_coffeescript = true

begin
  require 'coffee-script'

rescue Exception => e
  puts "WARNING: Skipping SC::Builder::Coffeescript tests because coffeescript is not installed."
  has_coffeescript = false
end

if has_coffeescript
  describe SC::Builder::Coffeescript do

    include SC::SpecHelpers
    include SC::BuilderSpecHelper

    before do
      std_before :coffeescript_test
      @manifest.add_entry 'icons/image.png'
    end

    after do
      std_after
    end   

    def run_builder(filename)
      super do |entry, dst_path|
        SC::Builder::Coffeescript.build(entry, dst_path)
      end
    end

    it 'should convert a simple coffee file into javascript' do
      lines = run_builder 'statement.coffee'
      matches = 0
      lines.each do |line|
        matches += 1 if line =~ /.*var\s*number/
      end
      matches.should == 1
    end    

    it "converts calls to sc_super() => arguments.callee.base.apply()" do
      lines = run_builder 'sc_super.coffee'

      matches = 0
      lines.each do |line|
        line.should_not =~ /sc_super/
        matches += 1 if line =~ /arguments.callee.base.apply\(this,arguments\)/
      end
      matches.should == 3
    end

    it "converts static_url() and sc_static() => 'url('foo')' " do
      lines = run_builder 'sc_static.coffee'

      matches = 0

      lines.each do |line|
        next if line.size == 1
        line.should_not =~ /(static_url|sc_static)/
        matches += 1 if line =~ /'.+'/ # important MUST have some url...
      end

      matches.should == 5
    end
  end
end
