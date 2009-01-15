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
  task :build => %w(manifest:prepare_stylesheets) do
    puts "BUILDING MANIFEST!"
  end

  desc "first step in building a manifest, this adds a simple copy file entry for every file in the source"
  task :catalog do |t|
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
  
  desc "localizes files. reject any files from other languages"
  task :localize => %w(manifest:hide_buildfiles) do
    seen = {} # already seen entries...
    preferred_language = TARGET.config.preferred_language || :en
    
    MANIFEST.entries.each do |entry|
      
      # Is a localized resource!
      if entry.filename =~ /^([^\/]+)\.lproj\/(.+)$/
        entry.language = (SC::Target::LONG_LANGUAGE_MAP[$1.to_s.downcase.to_sym]) || $1.to_sym
        entry.filename = $2
        entry.localized = true

        # remove .lproj dir from build paths as well..
        lang_dir = "#{$1}.lproj/"
        entry.build_path = entry.build_path.sub(lang_dir,'')
        entry.url = entry.url.sub(lang_dir,'')
        
        # if this is part of the current language, always include...
        # hide any preferred_language entry...
        if entry.language == MANIFEST.language
          seen[entry.filename].hide! if seen[entry.filename]
          
        # if this is a preferred_language, hide unless we've seen one
        elsif entry.language == preferred_language
          if seen[entry.filename]
            entry.hide!
          else
            seen[entry.filename] = entry
          end
        
        # Otherwise, hide it...
        else
          entry.hide!
        end
         
      # Not a localized resource
      else
        entry.language = MANIFEST.language
        entry.localized = false
      end
    end
  end
  
  desc "Removes fixtures from the list of entries unless config.load_fixtures is true"
  task :hide_fixtures => %w(manifest:localize) do
    unless CONFIG.load_fixtures
      MANIFEST.entries.each do |entry|
        entry.hide! if entry.filename =~ /^fixtures\/.+$/
      end
    end
  end
  
  desc "Removes any debug assets unless config.load_debug is true" 
  task :hide_debug => %w(manifest:hide_fixtures) do
    unless CONFIG.load_debug
      MANIFEST.entries.each do |entry|
        entry.hide! if entry.filename =~ /^debug\/.+$/
      end
    end
  end

  # Assign a normalized type to each entry.  Normalized types are used by 
  # later tasks to sort the entries into groups for post-processing.  The 
  # default implementation assigns each item a type of :html, :javascript,
  # :stylesheet, :test, :image, or :resource.  You can extend this to assign
  # different entry_types to an entry to do your own processing later.
  #
  task :assign_types => %w(manifest:hide_debug) do
    MANIFEST.entries.each do |entry|
      next if entry.entry_type
      
      # Compute entry type, possibly swapping entry for a transformed entry
      entry.entry_type = case entry.filename
      when /^tests\/.+/
        :test
      when /\.(rhtml|haml|html\.erb)$/
        :html
      when /\.(css|sass)$/
        :stylesheet
      when /\.js$/
        :javascript
      when /\.(jpg|png|gif)$/
        :image
      else
        :resource
      end
    end
  end
  
  # Build compiled entries for each :javascript entry.  Look inside the 
  # entry for an sc_resource('foo') call.  This will determine the resource
  # name.  If none is supplied, use 'javascript.js'.  
  task :prepare_javascripts => %w(manifest:assign_types) do
    entries = MANIFEST.entries.reject { |e| e.entry_type != :javascript }
    
    # sort entries by resource name
    sorted = {}
    entries.each do |entry|
      resource_name = 'javascript'
      File.readlines(entry.stage!.staging_path).each do |line|
        if line =~ /^\s*sc_resource\((["'])(.+)(\1)\)\s*\;/
          resource_name = $2
          break
        end
      end
      (sorted[resource_name] ||= []) << entry
    end
    
    # now generate composite javascript resources for each
    sorted.each do |resource_name, entries|
      MANIFEST.add_composite "#{resource_name}.js",
        :source_entries => entries, :build_task => 'build:javascript'
    end
  end

  # Build compiled entries for each :stylesheet entry.  Look inside the 
  # entry for an sc_resource('foo') call.  This will determine the resource
  # name.  If none is supplied, use 'stylesheet.css'.  
  task :prepare_stylesheets => %w(manifest:prepare_javascripts) do
    entries = MANIFEST.entries.reject { |e| e.entry_type != :stylesheet }
    
    # sort entries by resource name
    sorted = {}
    entries.each do |entry|
      resource_name = 'stylesheet'
      File.readlines(entry.stage!.staging_path).each do |line|
        if line =~ /^\s*\/\*\s*sc_resource\((["'])(.+)(\1)\)\s*\/\*/
          resource_name = $2
          break
        end
      end
      (sorted[resource_name] ||= []) << entry
    end
    
    # now generate composite javascript resources for each
    sorted.each do |resource_name, entries|
      MANIFEST.add_composite "#{resource_name}.css",
        :source_entries => entries, :build_task => 'build:stylesheet'
    end
  end

  # Build compiled entry for index.html.  Look inside the 
  # entry for an sc_resource('foo') call.  This will determine the resource
  # name.  If none is supplied, use 'stylesheet.css'.  
  task :prepare_stylesheets => %w(manifest:prepare_javascripts) do
    entries = MANIFEST.entries.reject { |e| e.entry_type != :stylesheet }
    
    # sort entries by resource name
    sorted = {}
    entries.each do |entry|
      resource_name = 'stylesheet'
      File.readlines(entry.stage!.staging_path).each do |line|
        if line =~ /^\s*\/\*\s*sc_resource\((["'])(.+)(\1)\)\s*\/\*/
          resource_name = $2
          break
        end
      end
      (sorted[resource_name] ||= []) << entry
    end
    
    # now generate composite javascript resources for each
    sorted.each do |resource_name, entries|
      MANIFEST.add_composite "#{resource_name}.css",
        :source_entries => entries, :build_task => 'build:stylesheet'
    end
  end
    
      
  
end
