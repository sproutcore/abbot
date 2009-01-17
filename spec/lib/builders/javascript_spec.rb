require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])
describe SC::Builder::Stylesheet do
  
  include SC::SpecHelpers

  before do
    @project  = temp_project :builder_tests
    @target   = @project.target_for :javascript_test
    @manifest = @target.manifest_for :language => :en
    @manifest.prepare!
    
    # add fake image entry for sc_static tests..
    @manifest.add_entry 'icons/image.png'
    
  end

  def run_builder(filename, localize=false)
    @entry = @manifest.add_entry filename # basic entry...
    @entry[:localized] = true if localize # needed for strings.js test...
    dst_path = @entry.build_path
    File.exist?(@entry.source_path).should be_true # precondition
    
    SC::Builder::JavaScript.build(@entry, dst_path) # perform build
    
    lines = File.readlines(dst_path)
    lines.size.should > 0 # make sure something built
    return lines
  end
    
  it "converts calls to sc_super() => arguments.callee.base.apply()" do
    lines = run_builder 'sc_super.js'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /sc_super\(/
      line.should =~ /arguments.callee.base.apply\(this,arguments\)/
    end
  end
      
  it "converts static_url() and sc_static() => 'url('foo')' " do
    lines = run_builder 'sc_static.js'
    lines.each do |line|
      next if line.size == 1
      line.should_not =~ /(static_url|sc_static)/
      line.should =~ /'.+'/ # important MUST have some url...
    end
  end
  
  it "removes server-side keys from localized strings.js files" do
    lines = run_builder 'strings.js', true
    @entry.should be_localized
    lines.each do |line|
      next if line.size == 1 # skip empty lines
      line.should_not =~ /@@foo/ # make sure key is removed...
    end
  end
      
  
end
