require "buildtasks/manifest/spec_helper"

# Creates combined entries for javascript & css
describe "Target#modules" do

  include SC::SpecHelpers
  include SC::ManifestSpecHelpers

  before do
    std_before
  end

  def run_task
    # capture any log warnings...
    @msg = capture('stderr') {
      @manifest.prepare!
      super('manifest:prepare_build_tasks:combine')
    }
  end

  describe "when a subset of modules are specified "  do

    before do
      run_task
    end

    it "does not require any modules in its requried_targets" do
      target = target_for('contacts')
      requirements = target.required_targets

      modules = requirements.select{ |target| target[:target_type] == :module }

      modules.should be_empty
    end

    it "contains only the specified modules" do
      target = target_for('contacts')
      modules = target.modules

      preferences_module = target_for('contacts/preferences')
      printing_module = target_for('contacts/printing')

      modules.should include(preferences_module)
      modules.should_not include(printing_module)
    end
  end

  describe "when a deferred modules requires another module "  do
    before do
      run_task
    end

    it "the deferred module should list the required module in its requirements" do
      target = target_for('mail')
      target_requirements = target.required_targets

      preferences_module = target.target_for('mail/preferences')
      printing_module = target.target_for('mail/printing')

      preferences_requirements = preferences_module.required_targets

      target_requirements.should_not include(preferences_module)
      preferences_requirements.should include(printing_module)
    end
  end

  describe "when an inline_module is defined"  do
    before do
      run_task
    end

    it "it should be included in the requirements" do
      target = target_for('photos')
      target_requirements = target.required_targets

      preferences_module = target.target_for('photos/preferences')
      email_module = target.target_for('photos/email')

      target_requirements.should include(preferences_module)
      target_requirements.should_not include(email_module)
    end
  end
end
