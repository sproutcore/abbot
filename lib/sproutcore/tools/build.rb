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

class MemoryProfiler
  DEFAULTS = {:delay => 1, :string_debug => false}

  def self.start(opt={})
    opt = DEFAULTS.dup.merge(opt)

    Thread.new do
      prev = Hash.new(0)
      curr = Hash.new(0)
      delta = Hash.new(0)

      file = File.open('log/memory_profiler.log','w')

      loop do
        begin
          GC.start
          curr.clear

          ObjectSpace.each_object do |o|
            curr[o.class] += 1 #Marshal.dump(o).size rescue 1
          end

          delta.clear
          (curr.keys + prev.keys).uniq.each do |k,v|
            if k == SproutCore::ManifestEntry and curr[k] < 300
              ObjectSpace.each_object do |o|
                if o.class == k
                  file.puts o[:source_path]
                  file.puts o.manifest.target[:target_name]
                  file.puts o.manifest.variation
                end
              end
            end
            delta[k] = curr[k]-prev[k]
          end

          file.puts "Top 10000"
          delta.sort_by { |k,v| -v.abs }[0..9999].sort_by { |k,v| -v}.each do |k,v|
            file.printf "%+5d: %s (%d)\n", v, k.name, curr[k] unless v == 0
          end
          file.flush

          delta.clear
          prev.clear
          prev.update curr
          GC.start
        rescue Exception => err
          STDERR.puts "** memory_profiler error: #{err}"
        end
        sleep opt[:delay]
      end
    end
  end
end

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
      
      MemoryProfiler.start
      GC::Profiler.enable

      # Get the manifests to build
      manifests = build_manifests(*targets) do |manifest|
        
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
