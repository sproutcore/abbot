require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe SC::Manifest, 'add_entry' do
  
  include SC::SpecHelpers

  before do
    @project = empty_project  # no buildfile to avoid running extra code...
    @project.add_target '/default', :default, :source_root => @project.project_root
    @target = @project.target_for :default
    @manifest = @target.manifest_for :language => :en
  end
    
  it "should add a new entry with the passed filename and any other options applied and return it" do
    entry = @manifest.add_entry 'filename', :extra_option => true
    entry.kind_of?(SC::ManifestEntry).should be_true
    entry.filename.should eql('filename')
    entry.extra_option.should be_true
  end
  
  it "calling with the same options each time should add a new instance" do
    entry1 = @manifest.add_entry 'filename', :extra_option => true
    entry2 = @manifest.add_entry 'filename', :extra_option => true
    entry1.foo = :entry1
    entry2.foo = :entry2
    
    entry1.foo.should eql(:entry1)
    entry2.foo.should eql(:entry2)
  end
  
  it "should call prepare! on the new entry" do
    entry = @manifest.add_entry 'filename', :extra_option => true
    entry.prepared?.should be_true
  end
  
end
