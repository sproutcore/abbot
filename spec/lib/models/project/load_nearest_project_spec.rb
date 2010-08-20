require "spec_helper"

describe SC::Project, 'load_nearest_project' do

  include SC::SpecHelpers

  it "should find the highest-level directory with a Buildfile" do
    # Note: since the fixtures live INSIDE the source directory and the
    # source directory contains a Buildfile, the _proper_ result here is to
    # actually return the top-level directory...
    project = SC::Project.load_nearest_project fixture_path('buildfiles', 'basic')
    project.project_root.should eql(fixture_path("buildfiles", "basic"))
  end

  it "should stop if it finds a Buildfile with project! set" do
    project = SC::Project.load_nearest_project fixture_path('buildfiles', 'project_test', 'not_project', 'child')

    # The Buildfile at project_test indicates that it is a project -- so it
    # should stop searching here...
    project.project_root.should eql(fixture_path('buildfiles', 'project_test'))
  end

end
