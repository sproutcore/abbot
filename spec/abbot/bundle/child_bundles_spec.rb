require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Abbot::Bundle, 'child_bundles' do
  
  include Abbot::SpecHelpers

  it "should be get bundles for direct apps and frameworks children in library -- should also look for apps in clients and apps dirs" do
    b = basic_library_bundle
    app_bundles = b.app_bundles
    framework_bundles = b.framework_bundles

    # Verify App Bundles -- look in clients && apps
    app_bundles.size.should eql(2)
    idx=0
    %w(app client).each do |key|
      cur = app_bundles[idx]
      fpath = fixture_path('basic_library', "#{key}s", "#{key}1")
      cur.source_root.should eql(fpath)
      cur.bundle_type.should eql(:app)
      idx += 1 
    end

    verify_bundles_match(framework_bundles, %w(lib1 lib2), :framework)
  end
  
  it "should get bundles for direct children in non-library bundles as well" do
    b = lib1_bundle
    app_bundles = b.app_bundles
    framework_bundles = b.framework_bundles
    root = %w(basic_library frameworks lib1)
    verify_bundles_match(app_bundles, %w(nested_app1), :app, root)
    verify_bundles_match(framework_bundles, %w(nested_lib1), :framework, root)
  end
  
  it "child_bundles should return both app and client bundles - sorted by name" do
    b = basic_library_bundle
    expected = [b.app_bundles, b.framework_bundles].flatten.sort do |a1,a2|
      a1.source_root <=> a2.source_root
    end

    idx = 0
    b.child_bundles.each do |cur|
      cur.should eql(expected[idx])
      idx += 1
    end
  end
  
  it "all_bundles should return all app & client bundles for children" do
    b = basic_library_bundle
    expected = all_bundles_for(b)
    idx=0;
    b.all_bundles.each { |x| x.should eql(expected[idx]); idx+=1 }
  end

  ################################################
  ## SUPPORT METHODS
  
  def verify_bundles_match(bundles, keys, type, root = 'basic_library')
    bundles.size.should eql(keys.size)
    idx=0
    keys.each do |key|
      cur = bundles[idx]
      fpath = fixture_path(root, "#{type}s", key)
      cur.source_root.should eql(fpath)
      cur.bundle_type.should eql(type)
      idx += 1 
    end
  end
    
  def all_bundles_for(b)
    ret = [b.child_bundles]
    b.child_bundles.each { |x| ret += all_bundles_for(x) }
    ret.flatten.compact.sort { |a,b| a.source_root <=> b.source_root }
  end
  
  
end
