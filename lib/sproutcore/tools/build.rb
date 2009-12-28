# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'manifest'))

$to_minify=''

module SC
  class Tools
    
    desc "build [TARGET..]", "Builds one or more targets"
    method_options(
      MANIFEST_OPTIONS.merge(:entries => :string, :clean => false))
      
    def build(*targets)

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
          
          entries.each do |entry|
            info "  #{entry.filename} -> #{entry.build_path}"
            entry.build!
          end
        end
      end
      yui_root = File.expand_path(File.join(LIBPATH, '..', 'vendor', 'yui-compressor'))
      jar_path = File.join(yui_root, 'SCyuicompressor-2.4.2.jar')
      filecompress = "java -jar " + jar_path + " --charset utf-8 --line-break 80 " + $to_minify + " 2>&1"
      SC.logger.info filecompress
      SC.logger.info  'Compressing with YUI:  '+ $to_minify + "..."
      
      output = `#{filecompress}`      # It'd be nice to just read STDERR, but
                                      # I can't find a reasonable, commonly-
                                      # installed, works-on-all-OSes solution.
      SC.logger.info output
        if $?.exitstatus != 0
        SC.logger.fatal(output)
        SC.logger.fatal("!!!!YUI compressor failed, please check that your js code is valid")
        SC.logger.fatal("!!!!Failed compressing ... "+ build_root)
        exit(1) 
      end
    end    
  end
end
