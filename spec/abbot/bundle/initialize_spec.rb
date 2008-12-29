require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'initialize' do
  
  include Abbot::SpecHelpers
  
  it "should require at least a source_root" do
    lambda { Abbot::Bundle.new }.should raise_error
    lambda { Abbot::Bundle.new :source_root => basic_library_path }.should_not raise_error
  end
  
  it "should assume :bundle_type => :library if not specified" do
    b = Abbot::Bundle.new :source_root => basic_library_path
    b.bundle_type.should eql(:library)
    b.parent_bundle.should be_nil
  end
  
  it "should require parent bundle if bundle_type != :library" do
    %w(framework app).each do |type|
      lambda { Abbot::Bundle.new :source_root => basic_library_path, :bundle_type => type.to_sym }.should raise_error
      
      lambda { Abbot::Bundle.new :source_root => fixture_path('basic_library', 'apps', 'app1'), :bundle_type => type.to_sym, :parent_bundle => basic_library_bundle }.should_not raise_error
    end
  end
  
  it "should require no parent bundle if bundle_type == :library" do
    lambda { Abbot::Bundle.new :source_root => basic_library_path, :bundle_type => :library }.should_not raise_error

    lambda { Abbot::Bundle.new :source_root => fixture_path('basic_library', 'apps', 'app1'), :bundle_type => :library, :parent_bundle => basic_library_bundle }.should raise_error
  end
  
  it "should allow next_bundle only if bundle_type == :library" do
    lambda { Abbot::Bundle.new :source_root => basic_library_path, :bundle_type => :library, :next_library => installed_library_bundle }.should_not raise_error
    lambda { Abbot::Bundle.new :source_root => fixture_path('basic_library', 'app1'), :bundle_type => :app, :next_library => installed_library_bundle, :parent_bundle => installed_library_bundle }.should raise_error
  end

  it "should have readers for source_root, bundle_type, and parent_bundle" do
    parent = basic_library_bundle
    b = app1_bundle(parent)
    b.source_root.should eql(fixture_path('basic_library', 'apps', 'app1'))
    b.bundle_type.should eql(:app)
    b.parent_bundle.should eql(parent)
  end
  
  it "should have is_library? return true if bundle_type == :library" do
    basic_library_bundle.is_library?.should be_true
    app1_bundle.is_library?.should be_false
  end
    
end