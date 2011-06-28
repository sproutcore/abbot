# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/tools/manifest"
require 'pathname'
include ObjectSpace
$to_html5_manifest = []
$to_html5_manifest_networks = []

module SC
  class Tools

    desc "build [TARGET..]", "Builds one or more targets"
    method_options(MANIFEST_OPTIONS)
    method_option :entries, :type => :string
    def build(*targets)
      stats = {}
      
      t1 = Time.now
      SC.logger.info  'Starting build process...'
      # Copy some key props to the env
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.staging_prefix = options.stageroot if options.stageroot
      SC.env.use_symlink    = options.symlink

      # Get entries option
      entry_filters = nil
      if options[:entries]
        entry_filters = options[:entries].split(',')
      end
      
      # We want Chance to clear files like sprites immediately after they're asked for, 
      # because we'll only need them once during a build.
      Chance.clear_files_immediately
      
      # Get the manifests to build
      manifests = build_manifests(*targets) do |manifest|
        # This is our own logic to prevent processing a manifest twice
        next if manifest[:built_by_builder]
        manifest[:built_by_builder] = true
        
        # get entries.  If "entries" option was specified, use to filter
        # filename.  Must match end of filename.
        entries = manifest.entries
        if entry_filters
          entries = entries.select do |entry|
            is_allowed = false
            entry_filters.each do |filter|
              is_allowed = entry.filename =~ /#{filter}$/
              break if is_allowed
            end
            is_allowed
          end
        end

        # if there are entries to build, log and build
        if entries.size > 0
          info "Building entries for #{manifest.target.target_name}:#{manifest.language}..."

          target_build_root = Pathname.new(manifest.target.project.project_root)
          entries.each do |entry|
            dst = Pathname.new(entry.build_path).relative_path_from(target_build_root)
            info "  #{entry.filename} -> #{dst}"
            entry.build!
          end
        end
        
        # Build dependencies
        target = manifest.target
        required = target.expand_required_targets :theme => true,
          :debug => target.config.load_debug,
          :tests => target.config.load_tests,
 
          # Modules are not 'required' technically, as they may be loaded
          # lazily. However, we want to know all targets that should be built,
          # so we'll include modules as well.
          :modules => true

        
        required.each {|t| 
          t.config[:minify_javascript] = false if not targets.include? t
          m = t.manifest_for (manifest.variation)
          
          
          # And, yes, the same as above. We're just building entries for all required targets.
          # We're also going to mark them as fully-built so they don't get built again.
          next if m[:built_by_builder]
          m[:built_by_builder] = true
          m.build!
          
          if m.entries.size > 0
            t[:built_by_builder]
            info "Building entries for #{m.target.target_name}:#{m.language}..."

            target_build_root = Pathname.new(m.target.project.project_root)
            m.entries.each do |entry|
              dst = Pathname.new(entry.build_path).relative_path_from(target_build_root)
              info "  #{entry.filename} -> #{dst}"
              entry.build!
            end
          end
          
          
        }
        
        # Clean up
        manifest.reset!
        Chance::ChanceFactory.clear_instances
      end

      if $to_html5_manifest.length > 0
        $to_html5_manifest.each do |entry|
          SC::Helpers::HTML5Manifest.new.build(entry)
        end
      end

      SC::Helpers::Minifier.wait

      t2 = Time.now
      seconds = t2-t1
      minutes = seconds/60
      seconds = seconds%60
      puts 'Build time '+minutes.floor.to_s+ ' minutes '+seconds.floor.to_s+' secs'
    end
  end
end
