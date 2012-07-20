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
    
    # Standard manifest options.  Used by build tool as well.
    method_option :languages, :type => :string,
      :desc => "The languages to build."
      
    method_option :symlink, :default => false
    
    method_option :buildroot, :type => :string,
      :desc => "The path to build to."
    method_option :stageroot, :type => :string,
      :aliases => %w(--target -t),
      :desc => "The path to stage to."
    method_option :format, :type => :string
    method_option :output, :type => :string
    method_option :all, :type => false
    method_option :build_numbers, :type => :string, :aliases => ['-B'],
      :desc => "The identifier(s) for the build."
    method_option :include_required, :default => false, :aliases => '-r',
      :desc => "Deprecated. All builds build dependencies."
      
    
    method_option :entries, :type => :string
    method_option :whitelist, :type => :string,
      :desc => "The whitelist to use when building. By default, Whitelist (if present)"
    method_option :blacklist, :type => :string,
      :desc => "The blacklist to use when building. By default, Blacklist (if present)"
    method_option :accept, :type => :string,
      :desc => "The SproutCore Accept file to determine which files to include. By default, Accept (if present)"
    method_option :allow_commented_js, :type => :boolean,
      :desc => "If supplied, commented JS will be allowed into the build."
    def build(*targets)
      if options.help
        help('build')
        return
      end

      t1 = Time.now
      SC.logger.info  'Starting build process...'
      # Copy some key props to the env
      SC.env.whitelist_name = options.whitelist
      SC.env.blacklist_name = options.blacklist
      SC.env.accept_name    = options.accept
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
        build_entries_for_manifest manifest, options.allow_commented_js
        
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
          m = t.manifest_for(manifest.variation)
          
          
          # And, yes, the same as above. We're just building entries for all required targets.
          # We're also going to mark them as fully-built so they don't get built again.
          next if m[:built_by_builder]
          m[:built_by_builder] = true
          m.build!
          
          build_entries_for_manifest m, options.allow_commented_js
          
          
        }
        
        # Clean up
        manifest.reset!
        Chance::ChanceFactory.clear_instances
      end

      # The HTML5 manifest generator does not work properly; it is unstable (can cause crashes)
      # and won't pick up modules. We need an alternative implemenation, preferably one that uses
      # Abbot's own manifests to figure out what files are required. This is non-trivial, however.
      #
      # if $to_html5_manifest.length > 0
      #   $to_html5_manifest.each do |entry|
      #     SC::Helpers::HTML5Manifest.new.build(entry)
      #   end
      # end

      SC::Helpers::Minifier.wait

      t2 = Time.now
      seconds = t2-t1
      minutes = seconds/60
      seconds = seconds%60
      puts 'Build time '+minutes.floor.to_s+ ' minutes '+seconds.floor.to_s+' secs'
    end
    
  end

end
