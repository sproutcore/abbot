require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

# The proxy helper defines proxy settings that can be used with sc-server
describe SC::Buildfile::Commands, 'proxy' do
  
  it "should save the opts for a new proxy" do
    b = SC::Buildfile.define do
      proxy '/url', :foo => :bar
    end
    b.proxies['/url'].foo.should eql(:bar)
  end

  it "should save the REPLACE opts for multiple calls to proxy" do
    b = SC::Buildfile.define do
      proxy '/url', :test1 => :foo, :test2 => :foo
      proxy '/url', :test1 => :bar
    end
    b.proxies['/url'].test1.should eql(:bar)
    b.proxies['/url'].test2.should be_nil
  end
  
  it "should merge multiple proxy urls and REPLACE opts for chained files" do
    a = SC::Buildfile.define do
      proxy '/url1', :test1 => :foo, :test2 => :foo
      proxy '/url2', :test1 => :foo
    end
    
    b = a.dup.define! do
      proxy '/url1', :test1 => :bar
    end
    
    b.proxies['/url1'].test1.should eql(:bar)
    b.proxies['/url1'].test2.should be_nil
    b.proxies['/url2'].test1.should eql(:foo)
  end
  
end

