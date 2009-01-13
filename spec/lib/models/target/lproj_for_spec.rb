require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

describe SC::Target, 'lproj_for' do

  include SC::SpecHelpers
  
  before do
    @project = fixture_project 'languages'
    @long_names = @project.target_for :long_names
    @short_names = @project.target_for :short_names    
  end
    

  it "should return the long name of a language if installed" do
    SC::Target::SHORT_LANGUAGE_MAP.each do |short_name, long_name|
      @long_names.lproj_for(short_name.to_sym).should eql("#{long_name}.lproj")
    end
  end
  
  it "should return the short name of a language if installed" do
    SC::Target::SHORT_LANGUAGE_MAP.each do |short_name, long_name|
      @short_names.lproj_for(short_name.to_sym).should eql("#{short_name}.lproj")
    end
  end
  
  it "should return the language name if installed + no explicit mapping" do
    @short_names.lproj_for('en-GB').should eql('en-GB.lproj')
  end
  
  it "should return nil for a non-existant language" do
    @short_names.lproj_for('imaginary').should be_nil
  end
  
  it "should return long language name if no mapping is known" do
    @long_names.lproj_for(:unknown).should eql('unknown.lproj')
  end
  
end
