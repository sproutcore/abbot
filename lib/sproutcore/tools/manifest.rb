module SC
  class Tools
    
    # Standard manifest options.  Used by build tool as well.
    MANIFEST_OPTIONS = { :languages     => :optional,
                         :symlink       => false,
                         :buildroot     => :optional,
                         :stageroot     => :optional,
                         :format        => :optional,
                         :output        => :output,
                         :all           => false,
                         ['--include-required', '-r'] => false }
                     
    desc "manifest [TARGET..]", "Generates a manifest for the specified targets"
    method_options(MANIFEST_OPTIONS)
    def manifest(*targets)

      # Copy some key props to the env
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.stating_prefix = options.stageroot if options.stageroot
      SC.env.use_symlink    = options.symlink 
      
      # Verify format
      format = (options.format || 'yaml').to_s.downcase.to_sym
      if ![:yaml, :json].include?(format)
        raise "Format must be yaml or json"
      end
      
      requires_project! # get project
      
      # If targets are specified, build a manifest specifically for those
      # targets.  Otherwise, build for all targets in the project.
      if (targets = find_targets(*targets)).size == 0
        targets = project.targets.values
        unless options.all? # remove those with autobuild turned off in config
          targets.reject! { |t| !t.config.autobuild? }
        end
      end
      SC.logger.info "Building targets: #{targets.map { |t| t.target_name } * ","}"
      
      # Use passed languages.  If none are specified, merge installed 
      # languages for all app targets.
      if (languages = options.languages).nil?
        languages = targets.map { |t| t.installed_languages }
      else
        languages = languages.split(':').map { |l| l.to_sym }
      end
      languages = languages.flatten.uniq.compact
      SC.logger.info "Building languages: #{ languages * "," }"
      
      # Now fetch the manifests to build.  One per target/language
      manifests = targets.map do |target|
        languages.map { |l| target.manifest_for :language => l }
      end
      manifests.flatten!
      
      # Build'em
      manifests.map! do |manifest| 
        SC.logger.info "Building manifest for: #{manifest.target.target_name}:#{manifest.language}"
        manifest.build!
        manifest.to_hash
      end
      
      # Serialize'em
      case format
      when :yaml
        output = manifests.to_yaml
      when :json
        output = mainfests.to_json
      end
      
      # output ...
      if options.output
        file = File.open(options.output, 'w')
        file.write(output)
        file.close
      else
        $stdout << output
      end
      
    end    
    
  end
end
