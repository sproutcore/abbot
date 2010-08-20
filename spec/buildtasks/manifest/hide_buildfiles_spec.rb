require "buildtasks/manifest/spec_helper"

describe "manifest:hide_buildfiles" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

    
  def run_task
    @manifest.prepare!
    super('manifest:hide_buildfiles')
  end
  
  it "should run manifest:catalog first" do
    should_run('manifest:catalog') { run_task }
  end
  
  it "should hide any Buildfile, sc-config, or sc-config.rb" do
    run_task
    entry_for('Buildfile').hidden?.should be_true
  end
  
  it "should hide any non .js file outside of .lproj, test, fixture, resources & debug dirs" do
    run_task
    entry_for('README').hidden?.should be_true
    entry_for('lib/index.html').hidden?.should be_true
    
    entry_for('tests/sample.rhtml').hidden?.should be_false
    entry_for('english.lproj/demo.html').hidden?.should be_false
    entry_for('fixtures/sample-json-fixture.json').hidden?.should be_false
    entry_for('resources/boo.png').hidden?.should be_false
    entry_for('debug/debug-resource.html').hidden?.should be_false
  end
  
  it "should NOT hide non-js files inslide lproj dirs" do
    run_task
    entry = entry_for('english.lproj/demo.html')
    entry.should_not be_hidden
  end

  describe "CONFIG.load_fixtures" do
    
    it "should hide files in /fixtures and /*.lproj/fixtures if CONFIG.load_fixtures is false" do
      @target.config.load_fixtures = false
      run_task
      entry = entry_for('fixtures/sample_fixtures.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/fixtures/sample_fixtures-loc.js')
      entry.should be_hidden
    end
  
    it "should NOT hide files in /fixtures and /*.lproj/fixtures if CONFIG.load_fixtures is true" do
      @target.config.load_fixtures = true
      run_task
      entry = entry_for('fixtures/sample_fixtures.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/fixtures/sample_fixtures-loc.js')
      entry.should_not be_hidden
    end
  end

  describe "CONFIG.load_debug" do
    it "should hide files in /debug and /*.lproj/debug if CONFIG.load_debug is false" do
      @target.config.load_debug = false
      run_task
      entry = entry_for('debug/sample_debug.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/debug/sample_debug-loc.js')
      entry.should be_hidden
    end
  
    it "should NOT hide files in /debug and /*.lproj/debug if CONFIG.load_fixtures is true" do
      @target.config.load_debug = true
      run_task
      entry = entry_for('debug/sample_debug.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/debug/sample_debug-loc.js')
      entry.should_not be_hidden
    end
  end

  describe "CONFIG.load_tests" do
    it "should hide files in /tests and /*.lproj/tests if CONFIG.load_tests is false" do
      @target.config.load_tests = false
      run_task
      entry = entry_for('tests/sample.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/tests/sample-loc.js')
      entry.should be_hidden
    end
  
    it "should NOT hide files in /tests and /*.lproj/tests if CONFIG.load_tests is true" do
      @target.config.load_tests = true
      run_task
      entry = entry_for('tests/sample.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/tests/sample-loc.js')
      entry.should_not be_hidden
    end
  end

  describe "CONFIG.load_protocols" do
    it "should hide files in /protocols and /*.lproj/protocols if config is false" do
      @target.config.load_protocols = false
      run_task
      entry = entry_for('protocols/sample.js')
      entry.should be_hidden
      entry = entry_for('english.lproj/protocols/sample-loc.js')
      entry.should be_hidden
    end
  
    it "should NOT hide files in /protocols  and /*.lproj/protocols if config is true" do
      @target.config.load_protocols = true
      run_task
      entry = entry_for('protocols/sample.js')
      entry.should_not be_hidden
      entry = entry_for('english.lproj/protocols/sample-loc.js')
      entry.should_not be_hidden
    end
  end
  
end
