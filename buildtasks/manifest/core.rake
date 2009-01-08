require 'tempfile'

namespace :manifest do
  
  desc "Computes the build path for the manifest.  This is used by all catalogs.  The default version will combine the bundle.build_root, language, and build number"
  task :compute_build_path do
    MANIFEST.build_path = File.join(BUNDLE.build_root.to_s, MANIFEST.language.to_s, BUNDLE.build_number.to_s)
  end
  
  desc "Computes the url path for the manifest.  The default version combines the bundle.url_root, language, and build number"
  task :compute_url_path do
    MANIFEST.url_path = [BUNDLE.url_root, MANIFEST.language.to_s, BUNDLE.build_number.to_s].join('/')
  end
  
  desc "Computes the path for staging files.  Unless you specify a staging_root in your config, a tmppath will be generated"
  task :compute_staging_path => :compute_build_path do
    staging_root = CONFIG.staging_root || File.join(Dir.tmpdir, 'sc-staging', Process.pid.to_s)
    MANIFEST.staging_path = File.join(staging_root, BUNDLE.bundle_name.to_s, MANIFEST.language.to_s, BUNDLE.build_number.to_s)
  end
    
end
