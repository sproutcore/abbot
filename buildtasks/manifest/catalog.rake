require 'tempfile'

namespace :manifest do
  
  desc "Creates a basic catalog of all files in the source_root.  When complete, the manifest would simply copy every file in the source_root to the build_root"
  task :catalog => [:compute_build_path, :compute_url_path, :compute_staging_path] do
    
    # Find all files in the source bundle and build an entry
    Dir.glob(File.join(BUNDLE.source_root, '**', '*')).each do |path| 

      # Skip directories
      next if File.directory?(path)

      # Skip files beginning with apps|clients|frameworks...
      filename = path.sub("#{BUNDLE.source_root}/", '')
      next if filename =~ /^(apps|clients|frameworks)/

      # Add entry for remaining files.  Note that the staging path for the
      # resource is the same as the source path, since no transforms will 
      # actually be performed on the file.  This will avoid unnecessary 
      # copying.
      MANIFEST.add_entry :filename => filename, 
        :source_path => path,
        :staging_path => path,
        :build_task => 'build:copy',
        :ext => (File.extname(path)[1..-1] || '')
    end
    
  end
  task :build => :catalog
  
end
