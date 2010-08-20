require "spec_helper"

describe SC::Target, 'installed_languages' do

  include SC::SpecHelpers
  
  before do
    @project = fixture_project 'languages'
  end
    
  def langs(langs)
    langs.map { |l| l.to_s }.sort.map { |l| l.to_sym }
  end
  
  it "should detect all installed languages with short names" do
    expected = langs %w(de en-CA en-GB en-US en es foo fr it ja)
    @short_names = @project.target_for :short_names
    @short_names.installed_languages.should eql(expected)
  end
  
  it "should map long languages to short names, and pass through others" do
    expected = langs %w(en fr de it ja es unknown)
    @long_names = @project.target_for :long_names
    @long_names.installed_languages.should eql(expected)
  end

  it "should always return the preferred language, even if no languages" do
    @no_names  = @project.target_for :no_names  
    @no_names.installed_languages.should eql([:en])
  end
  
  it "should ignore case for long names and respect case for unknown" do
    @long_names = @project.target_for :caps_long_names
    @long_names.installed_languages.should eql([:en, :fr, :UnknOWN])
  end
  
  # NOTE: This is the same test as above, but it is placed here to test 
  # case-sensitivity explicitly.  On some platforms, sorting will differ
  # depending on the case...
  it "should always return names using case insensitive sort" do
    @long_names = @project.target_for :caps_long_names
    @long_names.installed_languages.should eql([:en, :fr, :UnknOWN])
  end
    
  
  
end
