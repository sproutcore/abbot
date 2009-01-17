require File.expand_path(File.join(File.dirname(__FILE__), 'manifest'))

module SC
  class Tools
    
    desc "build [TARGET..]", "Builds one or more targets"
    method_options(
      MANIFEST_OPTIONS.merge(:entries => :optional, :clean => false))
      
    def build(*targets)

      # Copy some key props to the env
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.stating_prefix = options.stageroot if options.stageroot
      SC.env.use_symlink    = options.symlink 
      SC.env.clean          = options.clean 
      
      # Get entries option
      entry_filters = nil
      if options[:entries]
        entry_filters = options[:entries].split(',')
      end
      
      # Get the manifests to build
      manifests = build_manifests(targets)

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
          
          # if clean is enabled, first delete the build_root dir for the 
          # manifest.
          FileUtils.rm_r(manifest.build_root) if SC.env.clean 
          
          entries.each do |entry|
            info "  #{entry.filename} -> #{entry.build_path}"
            entry.build!
          end
        end
      end
      
    end    
    
  end
end
