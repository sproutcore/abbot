require File.join(File.dirname(__FILE__), 'spec_helper')

describe "manifest:localize" do
  
  include SC::SpecHelpers
  include SC::ManifestSpecHelpers
  
  before do
    std_before
  end

  def run_task
    @manifest.prepare!
    super('manifest:localize')
  end
  
  it "should run manifest:catalog && hide_buildfiles as prereq" do
    should_run('manifest:catalog') { run_task }
    should_run('manifest:hide_buildfiles') { run_task }
  end
  
  it "should not alter non-localized files" do
    run_task
    entry = entry_for('core.js')
    entry.should_not be_nil
    entry.should_not be_hidden
  end

  it "should mark all entries with localized? = true" do
    run_task
    @manifest.entries.each do |entry|
      if entry.source_path =~ /\.lproj/
        entry.localized?.should be_true
      else
        entry.localized?.should_not be_true
      end
    end
  end
  
  it "should remove foo.lproj from filename, build_path, and url of localized except for css and js files, which get 'lproj' instead" do
    run_task
    @manifest.entries.each do |entry|
      next unless entry.localized?
      new_filename = entry.source_path.match(/\.lproj\/(.+)$/).to_a[1]
      if entry.ext == 'js'
        new_filename = "lproj/#{new_filename}"
      end
      
      entry.filename.should eql(new_filename)
      entry.build_path = File.join(@manifest.build_root, new_filename.split('/'))
      entry.url = [@manifest.url_root, new_filename.split('/')].flatten.join('/')
    end
  end
  
  it "should assign language to localized entries" do
    run_task
    # we just test this by spot checking to make sure any entry in the
    # french.lproj actually has a french language code assigned...
    @manifest.entries.each do |entry|
      next unless entry.localize? && (entry.source_path =~ /french\.lproj/)
      entry.language.should eql(:fr) 
    end
  end
      
  it "should not hide resources in current language" do
    run_task
    entry = entry_for('lproj/french-resource.js')
    entry.localized?.should be_true
    entry.should_not be_hidden
    entry.language.should eql(:fr)
  end
  
  it "should not hide resource in preferred language that are not also found in current language" do
    run_task
    entry = entry_for('demo.html')
    entry.localized?.should be_true
    entry.language.should eql(:en)
    entry.should_not be_hidden
  end
  
  it "should prefer resource in current language over those in preferred language" do
    run_task
    # a 'strings.js' is defined in english.lproj, french.lproj, & german
    # this should use the french version since that one is current
    entry = @manifest.entry_for('lproj/strings.js')
    entry.localized?.should be_true
    entry.should_not be_hidden
    entry.language.should eql(:fr)
  end
    
  it "should hide resources in languages not part of current language or preferred language" do
    run_task
    entry = entry_for('lproj/german-resource.js')
    entry.should be_hidden
  end

end