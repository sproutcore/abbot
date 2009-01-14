# ===========================================================================
# SC::Manifest Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Manifest objects.  You can override these 
# tasks in your buildfiles.
namespace :manifest do
  
  desc "Invoked just before a manifest object is built to setup standard properties"
  task :prepare do
    require 'tempfile'

    # make sure a language was set
    MANIFEST.language ||= :en
    
    # build_root is target.build_root + language + build_number
    MANIFEST.build_root = File.join(TARGET.build_root, 
      MANIFEST.language.to_s, TARGET.build_number.to_s)
      
    # staging_root is target.staging_root + language + build_number
    MANIFEST.staging_root = File.join(TARGET.staging_root, 
      MANIFEST.language.to_s, TARGET.build_number.to_s)
      
    # url_root
    MANIFEST.url_root = 
      [TARGET.url_root, MANIFEST.language, TARGET.build_number].join('/')
      
    # index_root
    MANIFEST.index_root = 
      [TARGET.index_root, MANIFEST.language, TARGET.build_number].join('/')
      
    # source_root
    MANIFEST.source_root = TARGET.source_root
  end
  
  # Invoked to actually build a manifest.  This will invoke several other 
  # tasks on the same manifest.  In a Buildfile you may choose to extend or
  # override this task to provide your own manifest generation.
  task :build => :catalog do
    puts "BUILDING MANIFEST!"
  end

  desc "first step in building a manifest, this adds a simple copy file entry for every file in the source"
  task :catalog do
    source_root = TARGET.source_root
    Dir.glob(File.join(source_root, '**', '*')).each do |path|
      next if !File.exist?(path) || File.directory?(path)
      next if TARGET.target_directory?(path)
      filename = path.sub /^#{Regexp.escape source_root}\//, ''
      MANIFEST.add_entry filename # entry:prepare will fill in the rest
    end
  end
  
  desc "hides structural files that do not belong in build"
  task :hide_buildfiles => 'manifest:catalog' do
    MANIFEST.entries.each do |entry|
      # allow if inside lproj
      next if entry.localized? || entry.filename =~ /^.+\.lproj\/.+$/
      
      # otherwise, skip if ext not js
      entry.hide! if entry.ext != 'js'
    end
  end
  
    
end
