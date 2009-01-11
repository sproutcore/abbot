require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Project, 'targets' do

  include SC::SpecHelpers

  it "should clone targets from a parent project" do
    
    # Generate a dummy class to manually add a target.  This way we isolate
    # the tests for merging from tests of finding targets...
    test_project = Class.new(SC::Project) do
      def find_targets_for(root_path, root_name, config)
        self.add_target :base1, :dummy_type
      end
    end
    parent = test_project.new fixture_path('buildfiles', 'empty_project')
    
    # Now generate a real project with an empty path.  This should clone 
    # targets from the parent...
    project = SC::Project.new fixture_path('buildfiles', 'empty_project'), :parent => parent
    project.targets.size.should eql(1)
    project.targets['base1'].target_name.should eql(:base1)
  end
  
  # We want to test this because find_targets_for() is a callback we expect
  # people who customize the build tools to override.
  it "should invoke the find_targets_for method on itself" do
    
    # Generate dummy class with custom find_targets_for.
    test_project = Class.new(SC::Project) do
      
      attr_reader :did_call_find_targets_for
      attr_reader :passed_root_path
      attr_reader :passed_root_name
      attr_reader :passed_config
      
      def find_targets_for(root_path, root_name, config)
        @did_call_find_targets_for = true
        @passed_root_path = root_path
        @passed_root_name = root_name
        @passed_config = config
        return self
      end
    end
    
    # create project & get targets
    project = test_project.new fixture_path('buildfiles', 'empty_project')
    project.targets.size.should eql(0)
    
    # verify that callback method was run
    project.did_call_find_targets_for.should be_true
    project.passed_root_path.should eql(project.project_root)
    project.passed_root_name.should be_nil
    project.passed_config.should eql(project.config)
  end
    
end

