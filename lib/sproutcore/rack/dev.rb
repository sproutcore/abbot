# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require 'json'

module SC
  module Rack
    
    # Hosts general dev environment-related JSON assets.
    class Dev
      
      def initialize(project)
        @project = project
      end
      
      def call(env)
        url = env['PATH_INFO']
        case url
        when '/sc/targets.json' # returns description of targets
          return [200, {}, get_targets_json]
        else
          return [404, {}, "not found"]
        end
          
        return [404, {}, "not found"]
      end
      
      def get_targets_json
        targets = @project.targets.values.map do |target|
          target.prepare!
          parent = target.parent_target
          parent = parent.kind_of?(SC::Target) ? parent.target_name : ''
          {
            "name" => target.target_name,
            "kind" => target.target_type,
            "parent" => parent,
            "link_tests" => [target.url_root, 'en', target.build_number, 'tests', '-index.json'].join('/'),
            "link_docs"  => [target.url_root, 'en', target.build_number, 'docs', '-index.json'].join('/'),
            "link_root" => target.url_root
          }
        end
        targets.to_json
      end
      
    end
  end
end