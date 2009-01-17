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
  task :build => %w(catalog localize prepare_build_tasks:all) do
  end

  desc "first step in building a manifest, this adds a simple copy file entry for every file in the source"
  task :catalog do |t|
    source_root = TARGET.source_root
    Dir.glob(File.join(source_root, '**', '*')).each do |path|
      next if !File.exist?(path) || File.directory?(path)
      next if TARGET.target_directory?(path)
      filename = path.sub /^#{Regexp.escape source_root}\//, ''
      MANIFEST.add_entry filename, :original => true # entry:prepare will fill in the rest
    end
  end
  
  desc "hides structural files that do not belong in build include Buildfiles and debug or fixtures if turned off"
  task :hide_buildfiles => :catalog do
    # these directories are to be excluded unless CONFIG.load_"dirname" = true
    dirnames = %w(debug tests fixtures).reject { |k| CONFIG["load_#{k}"] }

    # loop through entries and hide those that do not below...
    MANIFEST.entries.each do |entry|

      # if in /dirname or /foo.lproj/dirname -- hide it!
      dirnames.each do |dirname|
        if entry.filename =~ /^(([^\/]+)\.lproj\/)?#{dirname}\/.+$/
          entry.hide!
          next
        end
      end
      
      # otherwise, allow if inside lproj
      next if entry.localized? || entry.filename =~ /^.+\.lproj\/.+$/
      
      # allow if in tests, fixtures or debug as well...
      next if entry.filename =~ /^(tests|fixtures|debug)\/.+$/
      
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
        entry.localized = true

        # remove .lproj dir from build paths as well..
        lang_dir = "#{$1}.lproj/"
        sub_str = (entry.ext == 'js') ? 'lproj/' : ''
        entry.filename   = entry.filename.sub(lang_dir, sub_str)
        entry.build_path = entry.build_path.sub(lang_dir, sub_str)
        entry.url        = entry.url.sub(lang_dir, sub_str)
        
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

  namespace :prepare_build_tasks do
    
    desc "main entrypoint for preparing all build tasks.  This should invoke all needed tasks"
    task :all => %w(tests javascript css html image sass combine) 

    desc "executes prerequisites needed before one of the subtasks can be invoked.  All subtasks that have this as a prereq"
    task :setup => %w(manifest:catalog manifest:hide_buildfiles manifest:localize)
    
    desc "create builder tasks for all unit tests based on file extension."
    task :tests => :setup do
      
      # Generate test entries
      test_entries = []
      MANIFEST.entries.each do |entry|
        next unless entry.filename =~ /^tests\//
        test_entries << MANIFEST.add_transform(entry, 
          :build_task => "build:test:#{entry.ext}",
          :entry_type => :test,
          :ext        => :html)
      end
      
      # Add summary entry
      if CONFIG.load_tests
        MANIFEST.add_entry 'tests/-index.json',
          :composite      => true, 
          :source_entries => test_entries,
          :build_task     => 'build:test:index.json',
          :entry_type     => :resource
      end
    end
    task :javascript => :tests # IMPORTANT! to avoid JS including unit tests.
    task :html       => :tests # IMPORTANT! to avoid HTML including tests

    desc "scans for javascript files, annotates them and prepares combined entries for each output target" 
    task :javascript => :setup do
      # select all original entries with with ext of css
      entries = MANIFEST.entries.select do |e| 
        e.original? && e.ext == 'js'
      end

      # add transform & tag with build directives.
      entries.each do |entry|
        entry = MANIFEST.add_transform entry,
          :build_task => 'build:javascript',
          :resource   => 'javascript',
          :entry_type => :javascript
        entry.discover_build_directives!
      end
      
    end

    desc "scans for css files, creates a transform and annotates them"
    task :css => :setup do
      
      # select all original entries with with ext of css
      entries = MANIFEST.entries.select do |e| 
        e.original? && e.ext == 'css'
      end

      # add transform & tag with build directives.
      entries.each do |entry|
        entry = MANIFEST.add_transform entry,
          :build_task => 'build:css',
          :resource   => 'stylesheet',
          :entry_type => :css
        entry.discover_build_directives!
      end
    end
    
    desc "generates combined entries for javascript and css"
    task :combine => %w(setup css javascript sass) do

      # sort entries...
      css_entries = {}
      javascript_entries = {}
      MANIFEST.entries.each do |entry|
        case entry.entry_type
        when :css
          (css_entries[entry.resource] ||= []) << entry
        when :javascript
          (javascript_entries[entry.resource] ||= []) << entry
        end
      end

      # build combined CSS entry
      css_entries.each do |resource_name, entries|
        MANIFEST.add_composite resource_name.ext('css'),
          :build_task     => 'build:combine:css',
          :source_entries => entries,
          :hide_entries   => CONFIG.combine_stylesheet
      end
      
      # build combined JS entry
      javascript_entries.each do |resource_name, entries|
        MANIFEST.add_composite resource_name.ext('js'),
          :build_task     => 'build:combine:javascript',
          :source_entries => entries,
          :hide_entries   => CONFIG.combine_javascript
      end
      
    end
    
    desc "create a builder task for all sass files to create css files"
    task :sass => :setup do
      MANIFEST.entries.each do |entry|
        next unless entry.ext == "sass"
        MANIFEST.add_transform entry,
          :build_task => 'build:sass',
          :entry_type => :css,
          :ext        => 'css',
          :resource   => 'stylesheet',
          :requires   => []
      end
    end
    
    desc "find all html-generating files, annotate and combine them"
    task :html => :setup do
      # select all entries with proper extensions
      known_ext = %w(rhtml erb haml)
      entries = MANIFEST.entries.select do |e| 
        (e.entry_type == :html) || (e.entry_type.nil? && known_ext.include?(e.ext))
      end

      # tag entry with build directives and sort by resource
      entries_by_resource = {}
      entries.each do |entry|
        entry.entry_type = :html
        entry.resource = 'index'
        
        entry.render_task = case entry.ext
        when 'rhtml':
          'render:erubis'
        when 'erb':
          "render:erubis"
        when 'haml':
          'render:haml'
        end
        
        # use a custom scan method since discover_build_directives! is too
        # general...
        
        entry.scan_source(/<%\s*sc_resource\(?\s*['"](.+)['"]\s*\)?/) do |m|
          entry.resource = m[0].ext ''
        end
        (entries_by_resource[entry.resource] ||= []) << entry
      end
      
      # Now, build combined entry for each resource
      entries_by_resource.each do |resource_name, entries|
        MANIFEST.add_composite resource_name.ext('html'),
          :build_task => 'build:html',
          :source_entries => entries
      end
    end
    
    desc "..."
    task :image => :setup do
    end
    
    
  end
      
  
end
