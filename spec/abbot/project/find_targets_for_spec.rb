require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Project, 'find_targets_for' do

  include Abbot::SpecHelpers
  
  # path for a target inside fixtures for this test
  def target_path(*args)
    fixture_path(*args.unshift('find_targets'))
  end
  
  # Should be a hash of target type -> array of expected target names
  def expect_targets(targets, expected_targets = {})
    known_targets = targets.keys
    expected_targets.each do | target_type, expected |
      expected.each do |target_name|
        target_name = target_name.to_sym
        known_targets.should include(target_name)
        targets[target_name].target_type.should eql(target_type)
        known_targets.delete target_name
      end
    end
  end
  
  it "should search recursively for apps, clients, and frameworks dirs with standard options -- also should ignore CaSeOfDir" do
    
    project = Abbot::Project.new(target_path('standard'), :parent => builtin_project)

    # verify preconditions
    target_types = project.config.target_types
    target_types.size.should eql(3)
    target_types[:apps].should eql(:app)
    target_types[:clients].should eql(:app)
    target_types[:frameworks].should eql(:framework)
    project.config.allow_nested_targets.should be_true
    
    # Note, this expectation assumes the fixtures in find_targets/standard has
    # the following:
    #  - different cases (see Apps + apps dirs)
    #  - an apps, clients, and frameworks directory
    #  - multiple targets in same dir (see framework1, framework2)
    #  - nesting one type inside another (see app1/framework1, app1/fmwk2)
    #  - nesting same type inside another (see framework1/framework1)
    #
    expect_targets project.targets, 
      :app => %w(/app1 /client1),
      :framework => %w(/framework1 /framework2 /app1/framework1 /app1/framework2 /framework1/framework1)
  end
  
  it "should find targets based on target_types hash, including overrides in  target Buildfiles" do
    
    project = Abbot::Project.new(target_path('custom'))
    
    # NOTE: find_targets_spec/custom/Buildfile defines foo & bar types
    # custom/foos/custom_foos/Buildfiels overrides.
    expect_targets project.targets,
      :foo => %w(/foo1 /custom_foos /custom_foos/foo1 /custom_foos/foo2 /bar1/foo1 /bar1/foo2),
      :bar => %w(/bar1 /bar1/bar1 /bar1/bar2 /foo1/bar1 /foo1/bar2)
    
  end
  
  it "should recursively find targets unless allows_nested_targets = false; should respect overrides in Buildfiles" do
    
    project = Abbot::Project.new(target_path('nested'))
    
    # NOTE: find_targets_spec/custom/Buildfile defines foo & bar types
    # custom/foos/custom_foos/Buildfiels overrides.
    expect_targets project.targets,
      :app => %w(/app1)
    project.targets['/app1/nested_app'].should be_nil
  end
  
  
end
  
