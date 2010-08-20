require "spec_helper"

describe SC::Buildfile::Commands, 'import' do

  include SC::SpecHelpers

  it "should import any tasks defined by the import" do
    buildfile1_path = fixture_path('buildfiles', 'installed', 'Buildfile')
    buildfile2_path = fixture_path('buildfiles', 'installed', 'Buildfile2')
    b = SC::Buildfile.define do 
      import buildfile1_path, buildfile2_path
    end
    b.task_defined?(:installed_task).should be_true
    b.task_defined?(:installed_task2).should be_true
  end

end
