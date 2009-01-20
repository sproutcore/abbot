require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Manifest, 'entry_for' do
  
  include SC::SpecHelpers

  before do
    @project  = fixture_project :entry_for_project
    @target   = @project.target_for :test_app
    @manifest = @target.manifest_for :language => :en
    @manifest.prepare!

    # manually add some entries for testing...
    
    # not hidden -- extra option :foo
    @manifest.add_entry 'entry.txt', 
      :hidden => false, 
      :foo    => :foo, 
      :item   => :visible_foo
    
    # duplicate of above w/ different :foo option
    @manifest.add_entry 'entry.txt', 
      :hidden => false, 
      :foo    => :bar, 
      :item   => :visible_bar
    
    # hidden
    @manifest.add_entry 'entry.txt', 
      :hidden => true, 
      :foo    => :foo, 
      :item   => :hidden
      
    # add other targets as well..
    @shared = @project.target_for(:shared).manifest_for(:language => :en)
    @shared.prepare!
    @shared.add_entry 'foobar/fake.png'
    
    @nested = @project.target_for('/test_app/nested').manifest_for(:language => :en)
    @nested.prepare!
    @nested.add_entry 'foobar/fake.png'
    
  end
    
  it "finds the first visible file matching the filename" do
    entry = @manifest.entry_for 'entry.txt'
    entry.should_not be_hidden
    [:visible_foo, :visible_bar].should include(entry.item) # either one is ok
  end
  
  it "finds the first hidden file matching the filename if :hidden => true is passed" do
    entry = @manifest.entry_for 'entry.txt', :hidden => true
    entry.should be_hidden
    entry.item.should == :hidden
  end
    
  
  it "finds the first file matching the filename and any additional passed options" do
    @manifest.entry_for('entry.txt', :foo => :foo).item.should == :visible_foo
    @manifest.entry_for('entry.txt', :foo => :bar).item.should == :visible_bar
  end
  
  it "requires an exact match on filename" do
    @manifest.entry_for('entry').should be_nil
  end
  
  it "returns nil if no matching entry could be found" do
    @manifest.entry_for('imaginary').should be_nil
  end
  
  describe "can name entries in other targets by prefixing entry name with target:entry_name" do
    
    it "will search another manifest" do
      entry = @manifest.entry_for('shared:foobar/fake.png')
      entry.should_not be_nil
      entry.manifest.should == @shared
    end
  
    it "will search for nested targets relative to current target" do
      entry = @manifest.entry_for('nested:foobar/fake.png')
      entry.should_not be_nil
      entry.manifest.should == @nested
    end
    
  end
  
end
