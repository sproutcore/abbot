# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
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

      #TODO: dry this up...also exists in SC::Rack::Filesystem
      def root_dir
        unless @root_dir
          @root_dir = @project.project_root
        end
        return @root_dir
      end

      def call(env)
        url = env['PATH_INFO']
        case url
        when '/sc/targets.json' # returns description of targets
          return [200, {}, get_targets_json]

        when '/sc/greenhouseconf.json' #returns json of all valid design objects
          return [200, {}, get_greenhouse_configs(env)]
        else
          return [404, {}, "not found"]
        end

        return [404, {}, "not found"]
      end

      def get_targets_json
        targets = @project.targets.values.map do |target|
          target.prepare!
          parent = target.parent_target
          parent = parent.kind_of?(SC::Target) ? parent[:target_name] : ''
          {
            "name" => target[:target_name],
            "kind" => target[:target_type],
            "parent" => parent,
            "link_tests" => [target[:url_root], 'en', target[:build_number], 'tests', '-index.json'].join('/'),
            "link_docs"  => [target[:url_root], 'en', target[:build_number], 'docs', '-index.json'].join('/'),
            "link_root" => target[:url_root]
          }
        end
        targets.to_json
      end

      def get_greenhouse_configs(env)
        rqust = ::Rack::Request.new(env)
        params = rqust.params
        app = params['app'] ? params['app'].to_sym : ''
        app_target = @project.target_for(app) 
        ret = []
        if(app_target)
          path = app_target.source_root + "/.greenhouseconf"
          json = File.exists?(path) ? JSON.parse(File.read(path)) : {}
          json[:path] = path.gsub(root_dir, "")
          json[:name] = app_target.target_name
          json[:canEdit] = true
          ret << json

          app_target.expand_required_targets.each do |target|
            path = target.source_root + "/.greenhouseconf"
            json = File.exists?(path) ? JSON.parse(File.read(path)) : {}
            if(path.include?(root_dir))
              json[:path] = path.gsub(root_dir, "")
              json[:canEdit] = true
            else
              json[:canEdit] = false
              json[:path] = path
            end
            json[:name] = target.target_name
            ret << json
          end
        end
        return ret.to_json
      end #end of get_greenhouse_configs

    end
  end
end
