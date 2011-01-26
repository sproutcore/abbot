require "buildtasks/manifest/spec_helper"

describe "manifest:prepare_build_tasks:module_info" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before :builder_tests, :module_test

    # run std rules to run manifest.  Then verify preconditions to make sure
    # no other changes to the build system effect the ability of these tests
    # to run properly.
    @manifest.build!

  end

  describe "when a target defines a deferred module" do

    it "should include a module_info entry" do
      module_info_entry = @manifest.entry_for('module_info.js')

      module_info_entry.should_not be nil
    end

    it "should contain all the modules and their requirements" do 
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      targets.length.should be 4
    end

  end

  describe "when a target defines an inlined module" do

    it "should include a module_info entry" do
      module_info_entry = @manifest.entry_for('module_info.js')

      module_info_entry.should_not be nil
    end

    it "should contain that module" do
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      inline_module = target_for('/module_test/inlined_module')

      targets.should include(inline_module)
    end

    it "should be marked as an inline module" do
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      inline_module = target_for('/module_test/inlined_module')

      inline_module[:inlined_module].should_not be nil
    end

  end

  describe "when a deferred module requires another module but that required module is defined as a prefetched module in the app" do

    it "it should be a prefetched module" do
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      required_target = target_for('/module_test/required_target')

      required_target[:prefetched_module].should be true
      targets.should include(required_target)
    end

    it "should be marked as a deferred module" do
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      required_target = target_for('/module_test/required_target')

      required_target[:deferred_module].should be nil
    end

  end

  describe "when a deferred module requires another module" do

    it "it includes its requirements in the module_info entry" do
      module_info = @manifest.entry_for('module_info.js')
      targets = module_info[:targets]

      targets.should include(target_for('/module_test/dynamic_req_target_1'))
    end

  end
end
