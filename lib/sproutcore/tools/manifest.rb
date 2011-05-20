# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC
  class Tools

    # Standard manifest options.  Used by build tool as well.
    MANIFEST_OPTIONS = { :symlink           => false,
                         :stageroot         => :string,
                         :format            => :string,
                         :output            => :string,
                         :all               => false,
                         :buildroot         => :string,
                         ['--languages', '-L']              => :string,
                         ['--build-numbers', '-B']          => :string,
                         ['--include-required', '-r']       => false }

    desc "manifest [TARGET..]", "Generates a manifest for the specified targets"
    method_options(MANIFEST_OPTIONS.merge(
      :format        => :string,
      :only          => :string,
      :except        => :string,
      :hidden        => false ))
    def manifest(*targets)

      # Copy some key props to the env
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.staging_prefix = options.stageroot if options.stageroot
      SC.env.use_symlink    = options.symlink

      # Verify format
      format = (options.format || 'yaml').to_s.downcase.to_sym
      if ![:yaml, :json].include?(format)
        raise "Format must be yaml or json"
      end

      # Get allowed keys
      only_keys   = Tools.get_allowed_keys(options[:only])
      except_keys = Tools.get_allowed_keys(options[:except])

      # call core method to actually build the manifests...
      manifests = build_manifests(*targets)

      # now convert them to hashes...
      manifests.map! do |manifest|
        manifest.to_hash :hidden => options.hidden,
          :only => only_keys, :except => except_keys
      end

      # Serialize'em
      case format
      when :yaml
        output = ["# SproutCore Build Manifest v1.0", manifests.to_yaml].join("\n")
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

    private
    def self.get_allowed_keys(keys)
      if keys
        result = (keys || '').to_s.split(',')
        result.map!(&:strip).map!(&:to_sym)
        result = nil if result.size == 0
        result
      end
    end

  end
end
