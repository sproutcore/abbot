require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Target, 'required_targets' do

  include SC::SpecHelpers

  before do
    @env = SC.build_mode # force debug mode
    SC.build_mode = :debug

    @project = fixture_project(:real_world)
  end
  
  after do
    SC.build_mode = @env
  end
    
  it "should resolve references to child targets" do
    target = @project.target_for :sproutcore
    
    # verify precondition 
    # -- the required property should NOT be array ...
    target.config.required.should eql(:desktop)
  
    expected = @project.target_for('sproutcore/desktop')
    
    target.required_targets.size.should eql(1)
    target.required_targets.first.should eql(expected)
  end
  
  it "should resolve references to siblings" do
    target = @project.target_for 'sproutcore/application'
  
    # verify precondition
    #  -- the required config should be an array
    target.config.required.size.should eql(2)
    
    expected = @project.target_for('sproutcore/costello')
    target.required_targets.size.should eql(2)
    target.required_targets.should include(expected)
  end
  
  it "should resolve references to other subtargets" do
    target = @project.target_for :mobile_photos
    target.required_targets.size.should eql(1)
    
    expected = @project.target_for('sproutcore/mobile')
    target.required_targets.first.should eql(expected)
  end
  
  it "should include any debug_required if passed :debug => true" do

    expected = @project.target_for 'sproutcore/debug'
    
    # verify load_debug = false
    target = @project.target_for 'sproutcore/desktop'
    target.config.debug_required = 'sproutcore/debug'
    target.required_targets().should_not include(expected)
    target.required_targets(:debug => false).should_not include(expected)
    target.required_targets(:debug => true).should include(expected)
  end

  it "should include any test_required if passed :test => true" do

    expected = @project.target_for 'sproutcore/qunit'
    
    # verify load_debug = false
    target = @project.target_for 'sproutcore/desktop'
    target.config.test_required = 'sproutcore/qunit'
    target.required_targets().should_not include(expected)
    target.required_targets(:test => false).should_not include(expected)
    target.required_targets(:test => true).should include(expected)
  end
  
  it "should log a warning if a required test or debug target could not be found" do
    
    target = @project.target_for :sproutcore
    target.config.test_required = 'imaginary_foo'
    target.config.debug_required = 'imaginary_bar'
    
    capture('stderr') { target.required_targets(:test => true) }.size.should_not == 0
    capture('stderr') { target.required_targets(:debug => true) }.size.should_not == 0
    
  end
  
  it "should include any CONFIG.theme if passed :theme => true && target_type == :app" do
    
    expected = @project.target_for 'sproutcore/standard_theme'
    
    target = @project.target_for :contacts
    target.target_type.should == :app # precondition
    target.config.theme = 'sproutcore/standard_theme'
    target.required_targets().should_not include(expected)
    target.required_targets(:theme => false).should_not include(expected)
    target.required_targets(:theme => true).should include(expected)

    target = @project.target_for :sproutcore
    target.target_type.should_not == :app # precondition
    target.config.theme = 'sproutcore/standard_theme'
    target.required_targets().should_not include(expected)
    target.required_targets(:theme => false).should_not include(expected)
    target.required_targets(:theme => true).should_not include(expected)
  end  
  
  it "should only find targets with a target type of :theme for CONFIG.theme" do
    # theme type
    expected = @project.target_for 'sproutcore/standard_theme'
    expected.target_type.should == :theme #precondition

    target = @project.target_for :contacts
    target.config.theme = 'sproutcore/standard_theme'
    target.required_targets(:theme => true).should include(expected)
    
    # non-theme type
    expected = @project.target_for 'sproutcore/costello'
    expected.target_type.should_not == :theme #precondition

    target = @project.target_for :calendar
    target.config.theme = 'sproutcore/costello'
    
    # should warn!
    result = nil
    capture('stderr') { result = target.required_targets(:theme => true) }.size.should > 0
    
    # and should not include theme
    result.should_not include(expected)
  end
  
end
