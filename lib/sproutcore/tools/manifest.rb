# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC
  class Tools

    # Standard manifest options.  Used by build tool as well.
    MANIFEST_OPTIONS = { :languages     => :string,
                         :symlink       => false,
                         :buildroot     => :string,
                         :stageroot     => :string,
                         :format        => :string,
                         :output        => :string,
                         :all           => false,
                         ['--build-numbers', '-B'] => :string
                         }

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
      only_keys = nil
      if options[:only]
        only_keys = (options[:only] || '').to_s.split(',')
        only_keys.map! { |k| k.to_sym }
        only_keys = nil if only_keys.size == 0
      end

      except_keys = nil
      if options[:except]
        except_keys = (options[:except] || '').to_s.split(',')
        except_keys.map! { |k| k.to_sym }
        except_keys = nil if except_keys.size == 0
      end

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

  end
end
