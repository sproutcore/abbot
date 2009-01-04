require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Buildfile, 'from' do

  include Abbot::SpecHelpers

  def test_detect(dirname, filename=nil)
    filename = dirname if filename.nil?

    p = fixture_path('buildfiles', dirname)
    b = Abbot::Buildfile.load(p)
    b.should_not be_nil
    b.path.should eql(File.join(p, filename))
  end
    
  it "should autodetect Buildfile" do
    test_detect 'basic', 'Buildfile'
  end
  
  it "should autodetect sc-config" do
    test_detect 'sc-config'
  end
  
  it "should autodetect sc-config.rb" do
    test_detect 'sc-config.rb'
  end
  
  it "should load the contents of the buildfile as well as imports" do
    p = fixture_path('buildfiles', 'basic')
    b = Abbot::Buildfile.load(p)
    
    b.should_not be_nil
    b.execute_task(:default)
    
    # Found in Buildfile
    RESULTS[:test_task1].should be_true
    
    # Found in import(task_module)
    RESULTS[:imported_task].should be_true
  end
  
  it "should be able to load the contents of one builfile on top of another" do
    a = Abbot::Buildfile.load(fixture_path('buildfiles','installed'))
    b = Abbot::Buildfile.load(fixture_path('buildfiles','basic'), a)
    
    b.execute_task :default
    
    # Found in Buildfile
    RESULTS[:test_task1].should be_true
    
    # Found in installed/Buildfile
    RESULTS[:installed_task].should be_true
  end
    
    
end