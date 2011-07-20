# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC
  class Tools

    desc "manifest [TARGET..]", "Generates a manifest for the specified targets"
    
    # Standard manifest options.  Used by build tool as well.
    method_option :languages, :type => :string,
      :desc => "The languages to build."
    method_option :symlink, :default => false
    method_option :buildroot, :type => :string,
      :desc => "The path to build to."
    method_option :stageroot, :type => :string,
      :desc => "The path to stage to."
    method_option :format, :type => :string
    method_option :output, :type => :string
    method_option :all, :type => false
    
    method_option :build_numbers, :type => :string, :aliases => ['-B'],
      :desc => "The identifier(s) for the build."
    method_option :include_required, :default => false, :aliases => '-r',
      :desc => "Deprecated. All builds build dependencies."
      
    method_option :format => :string
    method_option :only => :string
    method_option :except => :string
    method_option :hidden => false
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
