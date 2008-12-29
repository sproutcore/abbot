require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'is_bundle?' do
  
  include Abbot::SpecHelpers
  
  it "should identify a directory with sc-config, sc-config.rb, sc-config.yaml as bundle" do
    %w(ruby1 ruby2 yaml1 yaml2).each do |p|
      path = fixture_path('configs', p)
      Abbot::Bundle.is_bundle?(path).should be_true
    end
  end
  
  it "should identify a directory without sc-config as not bundle" do
    path = fixture_path('configs', 'not_bundle')
    Abbot::Bundle.is_bundle?(path).should be_false
  end
  
  it "should identify a non-existant directory as not a bundle" do
    path = "/imaginary/path"
    Abbot::Bundle.is_bundle?(path).should be_false
  end
end
