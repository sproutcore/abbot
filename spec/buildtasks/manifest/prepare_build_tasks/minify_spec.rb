require File.join(File.dirname(__FILE__), %w(.. spec_helper))

describe "manifest:prepare_build_tasks:minify" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:prepare_build_tasks:minify')
  end

  it "should run setup, javascript, css, and combine as prereq" do
    %w(setup javascript css sass scss less combine).each do |task_name|  
      should_run("manifest:prepare_build_tasks:#{task_name}") { run_task }
    end
  end
  
  describe "minify javascript tasks" do
    
    def should_have_minify_javascript_tasks
      entries = @manifest.entries.select { |e| e.entry_type == :javascript }
      entries.each do |entry|
        entry.should be_minified
        entry.should be_transform
        entry.source_entry.entry_type.should == :javascript
      end
    end

    def should_not_have_minify_javascript_tasks
      entries = @manifest.entries.select { |e| e.entry_type == :javascript }
      entries.each do |entry|
        entry.should_not be_minified
      end
    end
    
    it "adds task when CONFIG.minify_javascript == true" do
      @target.config.minify_javascript = true
      run_task
      should_have_minify_javascript_tasks
    end

    it "adds task when CONFIG.minify == true" do
      @target.config.minify = true
      @target.config.minify_javascript = nil # assume not defined
      run_task
      should_have_minify_javascript_tasks
    end

    it "does not add task when CONFIG.minify == true but CONFIG.minify_javascript == false" do
      @target.config.minify = true
      @target.config.minify_javascript = false
      run_task
      should_not_have_minify_javascript_tasks
    end

    it "does not add task when CONFIG.minify == false and CONFIG.minify_javascript is not defined" do
      @target.config.minify = false
      @target.config.minify_javascript = nil
      run_task
      should_not_have_minify_javascript_tasks
    end
    
  end
  
end
