require "spec_helper"

describe SC::Target, 'pack optimize !!!' do

  include SC::SpecHelpers

  before do
   	@project = temp_project :real_world

  end

  it "Returns two arrays:  targets that should be loaded packed,  Targets that should be loaded but not packed. In this case it should return one packed and 0 unpacked" do
	target = @project.target_for 'sproutcore/application'
	packed, unpacked = SC::Helpers::PackedOptimizer.optimize(target.required_targets)
	(packed.size + unpacked.size).should eql(1)
  end


  it "Returns two arrays:  targets that should be loaded packed,  Targets that should be loaded but not packed. In this case there shouln't be any packed target" do
	target = @project.target_for 'sproutcore'
	packed, unpacked = SC::Helpers::PackedOptimizer.optimize(target.required_targets)
	unpacked.size.should eql(1)
  end

end

