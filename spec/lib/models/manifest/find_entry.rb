require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Manifest, 'entry_for' do
  
  include SC::SpecHelpers

  before do
    @project  = fixture_project :entry_for_project
    @target   = @project.target_for :test_app
    @manifest = @target.manifest_for :language => :en
    @manifest.prepare!

    # manually add some entries for testing...

    # NOTE: the order these entries are added is important to the tests 
    # below.  See the test descriptions for more info.
    @manifest.add_entry 'foo'
    @manifest.add_entry 'images/foo.png'
    @manifest.add_entry 'images/foo.gif'
    @manifest.add_entry 'images/sprites/foo.png'
    @manifest.add_entry 'foo.png'
    
    @manifest.add_entry 'bark/bite.png',   :foo => :foo
    @manifest.add_entry 'bark/bite.png',   :foo => :bar
    @manifest.add_entry 'hidden/bite.png', :hidden => true
      
    # add an entry to shared for one later test also...
    @shared_man = @project.target_for(:shared).manifest_for(:language => :en)
    @shared_man.prepare!
    @shared_man.add_entry 'shared/foo.png'
  end
    
  def should_find(find_str, expected_filename)
    entry = @manifest.find_entry(find_str)
    entry.should_not be_nil
    entry.filename.should == expected_filename
  end
  
  it "matches exact path from url_root" do
    should_find('images/foo.png', 'images/foo.png')
  end
  
  it "returns first match based on order added, regardless of url depth" do
    should_find('foo.png', 'images/foo.png')
  end
  
  it "will match any extension if no extension is provided" do
    should_find('images/sprites/foo', 'images/sprites/foo.png')
  end
  
  it "will match first match if no extension is provided" do
    should_find('images/foo', 'images/foo.png')
  end

  it "providing extension can force match" do
    should_find('foo.gif', 'images/foo.gif')
  end
  
  it "prefers to match files with no extension over those with extension if no ext is provided" do
    should_find('foo', 'foo')
  end
  
  it "will match only visible unless :hidden => true" do
    @manifest.find_entry('hidden/bite.png').should be_nil
    @manifest.find_entry('hidden/bite.png', :hidden => true).should_not be_nil
  end
  
  it "will also match based on additional passed options" do
    entry = @manifest.find_entry('bark/bite.png', :foo => :bar)
    entry.should_not be_nil
    entry.foo.should == :bar
    
    entry = @manifest.find_entry('bark/bite.png', :foo => :foo)
    entry.should_not be_nil
    entry.foo.should == :foo
  end
  
  it "will search required targets if the requested resource is not found in current manifest" do
    entry = @manifest.find_entry('shared/foo')
    entry.should_not be_nil
    entry.manifest.should == @shared_man # verify came from other manifest...
  end
  
end
