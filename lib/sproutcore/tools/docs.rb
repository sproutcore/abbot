# -*- coding: utf-8 -*-
# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'manifest'))

module SC
  class Tools

    desc "sc-docs [TARGET..]", "Generates JSDoc's for specified targets."
    method_options(:entries => :optional,
                   :clean => false,
                   '-r' => false)
    def docs(*targets)

      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.clean          = options.clean
      SC.env.build_required = options.r

      manifests = build_manifests(targets)

      # First clean all manifests
      # Do this before building docs so we don't accidentally erase already
      # built nested targets docs.
      
      manifests.each do |manifest|
        target = manifest.target
        build_root = target.project.project_root + "/tmp/docs#{target.target_name}"
        if target.target_type == :framework ||
            target.target_type == :app
          if SC.env.clean
            SC.logger.info "Cleaning #{build_root}"
            FileUtils.rm_r(build_root) if File.directory?(build_root)
          end
        end
        target.build_docs!(build_root)
      end
    end
  end
end
