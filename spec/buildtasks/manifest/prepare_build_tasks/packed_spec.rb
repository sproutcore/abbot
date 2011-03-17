require "buildtasks/manifest/spec_helper"

# Creates packed combined entries for javascript & css
describe "manifest:prepare_build_tasks:packed" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before(:real_world, :no_2x)
  end

  def run_task
    # By default, no_2x will require sproutcore, which in the fixtures, has 2x.
    # So, we'll end up with a 2x file even though we shouldn't have one.
    # In chance_2x_indirect, we'll test :no_2x, but drop this part
    @target.config[:required] = []


    # capture any log warnings...
    @msg = capture('stderr') {
      @manifest.prepare!
      super('manifest:prepare_build_tasks:packed')
    }
  end

  it "should run setup, combine as prereq" do
    %w(setup combine).each do |task_name|
      should_run("manifest:prepare_build_tasks:#{task_name}") { run_task }
    end
  end

  it "should add packed entries for apps" do
    @target = @project.target_for(:contacts)
    @target.target_type.should == :app # precondition

    @manifest = @target.manifest_for(:language => :en)
    run_task

    @manifest.entry_for('javascript-packed.js').should_not be_nil
    @manifest.entry_for('stylesheet-packed.css').should_not be_nil

    # In this version, there should _not_ be an @2x entry.
    @manifest.entry_for('stylesheet@2x-packed.css').should be_nil
  end

  it "should remove non-packed JS entries from apps" do
    @manifest.entries.each do |entry|
      if entry[:entry_type] == :javascript
        entry[:filename].should eq 'javascript-packed.js'
      end
    end
  end

  it "should not add packed entries for frameworks" do
    # verify default target is a framework - precondition
    @target.target_type.should == :framework #precondition
    run_task

    @manifest.entry_for('javascript-packed.js').should be_nil
  end

  #######################################
  # javascript-packed.js support
  #
  describe "javascript-packed.js" do

    before do
      @target = @project.target_for(:contacts)
      @target.target_type.should == :app # precondition

      @manifest = @target.manifest_for(:language => :en)

      run_task
      @entry = entry_for('javascript-packed.js')
    end

    it "should generate a javascript-packed.js entry" do
      @entry.should_not be_nil
    end

    it "should include javascript.js entries from all required targets" do
      @entry.source_entries.size.should > 0
      @entry.source_entries.each do |entry|
        entry.filename.should == 'javascript.js'
      end
    end

    it "should include ordered_entries ordered by required target order" do

      # find targets, sorted by order.  remove any that don't have a
      # javascript.js entry.
      targets = @target.expand_required_targets(:theme => true) + [@target]
      variation = @entry.manifest.variation
      targets.reject! do |t|
        t.manifest_for(variation).build!.entry_for('javascript.js').nil?
      end

      @entry.ordered_entries.each do |entry|
        entry.target.should == targets.shift
      end
    end

    it "should include the actual targets this packed version covers in the targets property (even those w no javascript.js)" do
      targets = @target.expand_required_targets(:theme => true) + [@target]
      @entry.targets.should == targets
    end

    it "should NOT include minified source entries" do
      @entry.source_entries.each do |entry|
        entry.should_not be_minified
      end
    end

    it "should be marked as packed" do
      @entry.should be_packed
    end

  end

  #######################################
   # stylesheet-packed.css support
   #
   describe "stylesheet-packed.css" do

     before do
      @target = @project.target_for(:contacts)
      @target.target_type.should == :app # precondition

      @manifest = @target.manifest_for(:language => :en)


       run_task

       @entry = entry_for('stylesheet-packed.css')
       @entry_2x = entry_for('stylesheet@2x-packed.css')
     end

     it "should generate a stylesheet-packed.css entry" do
       @entry.should_not be_nil

       # should be _no_ @2x entry for this version (see packed_2x_spec)
       # because the @2x version is only included as-needed.
       @entry_2x.should be_nil
     end

     it "should include stylesheet.css entries from all required targets" do
       @entry.source_entries.size.should > 0
       @entry.source_entries.each do |entry|
         entry.filename.should == 'stylesheet.css'
       end
     end

     it "should include ordered_entries ordered by required target order" do

       # find targets, sorted by order.  remove any that don't have a
       # stylesheet.css entry.
       targets = @target.expand_required_targets(:theme => true) + [@target]
       variation = @entry.manifest.variation
       targets.reject! do |t|
         t.manifest_for(variation).build!.entry_for('stylesheet.css').nil?
       end

       @entry.ordered_entries.each do |entry|
         entry.target.should == targets.shift
       end

     end

     it "should include the actual targets this packed version covers in the targets property (even those w no stylesheet.css)" do
       targets = @target.expand_required_targets(:theme => true) + [@target]
       @entry.targets.should == targets
     end

     it "should NOT include minified source entries" do
       @entry.source_entries.each do |entry|
         entry.should_not be_minified
       end
     end

     it "should be marked as packed" do
       @entry.should be_packed
     end

   end

end
