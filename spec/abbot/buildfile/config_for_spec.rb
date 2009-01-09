require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

buildfile = nil

# This should return the merged config setting for the named options
describe Abbot::Buildfile, 'config_for' do
  
  before do
    @buildfile = Abbot::Buildfile.define do
      
      # all - all
      config :all,
        :test1 => :all_all,
        :test2 => :all_all,
        :test3 => :all_all,
        :test4 => :all_all
        
      # debug - all
      mode :debug do
        config :all,
          :test2 => :debug_all,
          :test4 => :debug_all
      end

      mode :production do
        config :all,
          :test2 => :production_all,
          :test4 => :production_all
      end
      
      # all - bundle
      config :foo, :test3 => :all_foo, :test4 => :all_foo
      config :bar, :test3 => :all_bar, :test4 => :all_bar
        
      # debug - bundle 
      mode :debug do
        config :foo, :test4 => :debug_foo
        config :bar, :test4 => :debug_bar
      end
      
      mode :production do
        config :foo, :test4 => :production_foo
        config :bar, :test4 => :production_bar
      end
      
    end

  end
  
  def test_config(target_key, mode_name)
    target_name = target_key.to_s.sub /^([^\/])/,'/\1'
    config = @buildfile.config_for(target_name, mode_name)
    config.test1.should eql(:all_all)
    config.test2.should eql("#{mode_name}_all".to_sym)
    config.test3.should eql("all_#{target_key}".to_sym)
    config.test4.should eql("#{mode_name}_#{target_key}".to_sym)
  end
  
  it "config_for(all, all) should exclude all specific mode/bundle settings" do
    test_config :all, :all
  end
  
  it "config_for(all, mode) should exclude specific bundle settings" do
    test_config :all, :debug
    test_config :all, :production
  end
  
  it "config_for(bundle, :all) should exclude specific mode settings" do
    test_config :foo, :all
    test_config :bar, :all
  end
  
  it "config_for(bundle,mode) should exclude other modes or bundles, but include all" do
    test_config :foo, :debug
    test_config :bar, :debug
    test_config :foo, :production
    test_config :bar, :production
  end
  
end

