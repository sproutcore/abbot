# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/tools/manifest"
require 'pathname'

$to_html5_manifest = []
$to_html5_manifest_networks = []

module SC
  class Tools

    desc "build [TARGET..]", "Builds one or more targets"
    method_options(MANIFEST_OPTIONS)
    method_option :entries, :type => :string
    method_option :clean,   :type => :boolean, :aliases => "-c"
    def build(*targets)
      t1 = Time.now
      SC.logger.info  'Starting build process...'
      # Copy some key props to the env
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.staging_prefix = options.stageroot if options.stageroot
      SC.env.use_symlink    = options.symlink
      SC.env.clean          = options.clean

      # Get entries option
      entry_filters = nil
      if options[:entries]
        entry_filters = options[:entries].split(',')
      end

      # Get the manifests to build
      manifests = build_manifests(*targets)

      # First clean all manifests
      # Do this before building so we don't accidentally erase already build
      # nested targets.
      if SC.env.clean
        manifests.each do |manifest|
          build_root = manifest.target.build_root
          info "Cleaning #{build_root}"
          FileUtils.rm_r(build_root) if File.directory?(build_root)

          staging_root = manifest.target.staging_root
          info "Cleaning #{staging_root}"
          FileUtils.rm_r(staging_root) if File.directory?(staging_root)
        end
      end

      # Now build entries for each manifest...
      manifests.each do |manifest|

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
