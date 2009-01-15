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

  desc "Actually builds a manifest.  This will catalog all entries and then filter them"
  task :build => %w(manifest:catalog manifest:localize) do
    puts "BUILDING MANIFEST! - #{SC.build_mode} - load_debug = #{CONFIG.load_debug} - load_fixtures = #{CONFIG.load_fixtures}"
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
  
  desc "hides structural files that do not belong in build include Buildfiles and debug or fixtures if turned off"
  task :hide_buildfiles => :catalog do
    load_debug = CONFIG.load_debug
    load_fixtures = CONFIG.load_fixtures
    MANIFEST.entries.each do |entry|
      # if in /debug or /foo.lproj/debug  - hide...
      if !load_debug && entry.filename =~ /^(([^\/]+)\.lproj\/)?debug\/.+$/
        entry.hide!
        next
      end
      
      # if in /fixtures or /foo.lproj/fixtures - hide...
      if !load_fixtures && entry.filename =~ /^(([^\/]+)\.lproj\/)?fixtures\/.+$/
        entry.hide!
        next
      end
      
      # otherwise, allow if inside lproj
      next if entry.localized? || entry.filename =~ /^.+\.lproj\/.+$/
      
      # or skip if ext not js
      entry.hide! if entry.ext != 'js'
    end
  end
  
  desc "localizes files. reject any files from other languages"
  task :localize => [:catalog, :hide_buildfiles] do
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
  
  desc "assigns a normalized type to each entry.  These types will be used to control all the future filters"
  task :assign_types => :localize do
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
