require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Project, 'buildfile' do

  include SC::SpecHelpers

  it "should return a new, empty buildfile if no Buildfile can be found in the project" do
    project = SC::Project.new fixture_path('buildfiles', 'empty_project')
    puts project.buildfile.loaded_paths
    project.buildfile.loaded_paths.size.should eql(0)
    project.buildfile.tasks.size.should eql(0)
  end
  
  it "should load a buildfile if one is found in project_root" do
    project = SC::Project.new fixture_path('buildfiles', 'installed')
    project.buildfile.loaded_paths.size.should eql(1)
    project.buildfile.tasks.size.should eql(2)
  end
  
  it "should load all files matching SC.env.buildfile_names" do
    SC.env.buildfile_names = ['Buildfile', 'Buildfile2']
    project = SC::Project.new fixture_path('buildfiles', 'installed')
    project.buildfile.loaded_paths.size.should eql(2)
    SC.env.delete :buildfile_names
  end

  it "should merge over top of a parent project buildfile if there is one" do
    installed = SC::Project.new fixture_path('buildfiles', 'installed')
    basic = SC::Project.new fixture_path('buildfiles', 'basic'), :parent => installed
    basic.buildfile.lookup(:installed_task).should_not be_nil
    basic.buildfile.lookup(:test_task1).should_not be_nil
  end
  
end

