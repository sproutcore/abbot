# -*- coding: utf-8 -*-
# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/tools/manifest"

module SC
  class Tools

    desc "docs [TARGET..]", "Generates JSDoc's for specified targets."
    method_options(:entries  => :string,
                   :clean    => true,
                   :language => :string,
                   :template => :string,
                   ['--include-required', '-r'] => false)
    def docs(*targets)

      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.clean          = options.clean
      SC.env.build_required = options['include-required']
      SC.env.language       = options.language
      SC.env.template_name  = options.template

      # Find all the targets
      targets = find_targets(*targets)
      targets.each do |target|
        project_root = target.project.project_root
        build_root = project_root / 'tmp' / 'docs' / target.target_name.to_s

        if [:framework, :app].include?(target.target_type)
          if SC.env.clean
            SC.logger.info "Cleaning #{build_root}"
            FileUtils.rm_r(build_root) if File.directory?(build_root)
          end

          target.build_docs!(:build_root => build_root,
            :language => SC.env.language,
            :required => true, #SC.env.build_required,
            :template => SC.env.template_name,
            :logger   => SC.logger)
        else
          SC.logger.info "#{target.target_name} is not of type framework or app. Skipping."
          SC.logger.info "#{target.target_name} is of type #{target.target_type}."

        end # if [:framework, :app]
      end # targets.each
    end # def docs
  end # class Tools
end # module SC
