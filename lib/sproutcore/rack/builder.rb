# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require 'thread'

module SC
  module Rack

    # A Rack application for serving dynamically-built SproutCore projects.
    # Most of the time you will use this application as part of the sc-server
    # command to dynamically build your SproutCore project while you develop
    # it.
    #
    # If you are deploying some Ruby-based infrastructure in your production
    # environment, you could also use this application to dynamically build
    # new versions of your SproutCore apps when you deploy them.  This would
    # allow you to potentially bypass the pre-deployment build step using
    # sc-build.
    #
    # While this model is supported by the Rack adaptor, it is generally
    # recommended that you instead build you app without using this adaptor
    # since the build step will help catch possible errors in your code before
    # you go live with your project.  Sometimes, however, dynamically building
    # content is useful, and that is what this adaptor is for.
    #
    # === Using This Application
    #
    # When you instantiate a builder, you must provide one or more projects
    # that contain the resources you want to load.  Each incoming request url
    # will be mapped to an entriy in a project manifest.  The entry is then
    # built and the resulting file returned.  Once a file has been built, it
    # will not be rebuilt unless the source file it represents has changed.
    #
    # In addition to dynamically building entries, the Builder can also
    # forwards requests onto an SC::Rack::Proxy app to handle proxies
    # requests.
    #
    # === Config Settings
    #
    # This app respects several options that you can name in your config file
    # (in addition to proxy configs), that can affect the app performance.
    # Normally reasonable defaults for these settings are built into the
    # SproutCore buildfile, but you may choose to override them if you are
    # deploying into a production environment.
    #
    #  :reload_project::  If set to true, then the builder will reload the
    #    projects to look for changed files before servicing incoming
    #    requests.  You will generally want this option while working in
    #    debug mode, but you may want to disable it for production, since it
    #    can slow down performance.
    #
    #  :use_cached_headers:: If set to true, then the builder will return
    #    static assets with an "Expires: <10-years>" header attached.  This
    #    will yield excellent performance in production systems but it may
    #    interfere with loading the most recent copies of files when in
    #    development mode.
    #
    #  :combine_javascript:: If set, the generated html will reference a
    #    combined version of the javascript for elgible targets.  This will
    #    yield better performance in production, but slows down load time in
    #    development mode.
    #
    #  :combine_stylesheets:: Ditto to combine_javascript
    #
    class Builder

      # used to set expires header.
      ONE_YEAR = 365 * 24 * 60 * 60

      # When you create a new builder, pass in one or more projects you want
      # the builder to monitor for changes.
      def initialize(project)
        @project = project
        @last_reload_time = Time.now
      end

      # Main entry point for this Rack application.  Returns 404 if no
      # matching entry could be found in the project.
      def call(env)
        # define local variables so they will survive the mutext contexts
        # below...
        ret = url = target = language = cacheable = manifest = entry = nil
        build_path = nil

        project_mutex.synchronize do
          did_reload = reload_project! # if needed

          # set SCRIPT_NAME to correctly set namespaces
          $script_name = env["SCRIPT_NAME"]

          # collect some standard info
          url = env['PATH_INFO']
          url = '/sproutcore/welcome' if url == '/'

          #designer mode?
          $design_mode = ((/designMode=YES/ =~ env['QUERY_STRING']) != nil) ? true : false

          # look for a matching target
          target = target_for(url)
          ret = not_found("No matching target") if target.nil?

          # normalize url to resolve to entry & extract the language
          if ret.nil?
            url, language, cacheable = normalize_url(url, target)
            ret = not_found("Target requires language") if language.nil?
          end

          # lookup manifest
          if ret.nil?
            language = language.to_s.downcase.to_sym # normalize
            manifest = target.manifest_for(:language => language).build!

            # lookup entry by url
            unless entry = manifest.entries.find { |e| e[:url] == url }
              ret = not_found("No matching entry in target")
            end
          end

          if ret.nil?
            build_path = entry[:build_path]
            if [:html, :test].include?(entry[:entry_type])
              #if did_reload || !File.exist?(build_path)
              #always clean html files...
              SC.profile("PROFILE_BUILD") do
                entry.clean!.build!
              end
            else
              entry.build!
            end

          end

          # Update last reload time.  This way if any other requests are
          # waiting, they won't rebuild their manifest.
          @last_reload_time = Time.now
        end

        return ret unless ret.nil?

        unless File.file?(build_path) && File.readable?(build_path)
          return not_found("File could not build (entry: #{entry.filename} - build_path: #{build_path}")
        end

        SC.logger.info "Serving #{target[:target_name].to_s.sub(/^\//,'')}:#{entry[:filename]}"

        # define response headers
        file_size = File.size(build_path)
        headers = {
          #"Last-Modified"  => File.mtime(build_path).httpdate,
          #"Etag"           => File.mtime(build_path).to_i.to_s,
          "Content-Type"   => mime_type(build_path, target.config[:mime_types]),
          "Content-Length" => file_size.to_s,
          "Expires"        => (cacheable ? (Time.now + ONE_YEAR) : Time.now).httpdate
        }
        [200, headers, File.open(build_path, 'rb')]
      end

      attr_reader :project

      protected

      # Mutex used while updating the project and retrieving the entry to
      # build.
      def project_mutex; @project_mutex ||= Mutex.new; end

      # Mutex used while building an entry...
      def build_mutex; @build_mutex ||= Mutex.new; end

      # Invoked when a resource cannot be found for some reason
      def not_found(reason)
        reason = "<html><body><p>#{reason}</p></body></html>"
        return [404, {
          "Content-Type"   => "text/html",
          "Content-Length" => reason.size.to_s
        }, reason]
      end

      # Reloads the project if reloading is enabled.  At maximum this will
      # reload the project every 5 seconds.
      def reload_project!

        monitor_project!

        # don't reload if no project or is disabled
        return false if @project.nil? || !@project.config[:reload_project]

        _did_reload = false

        if @project_did_change
          @project_did_change = false
          SC.logger.info "Rebuilding project manifest"
          @project.reload!
          _did_reload = true
        end

        _did_reload
      end

      def monitor_project!
        if !@should_monitor
          @should_monitor = true
          @project_root = @project.project_root

          # collect initial info on project
          files = Dir.glob(@project_root / '**' / '*')
          # follow 1-level of symlinks
          files += Dir.glob(@project_root / '**' / '*' / '**' / '*')
          tmp_path = /^#{Regexp.escape(@project_root / 'tmp')}/
          files.reject! { |f| f =~ tmp_path }
          files.reject! { |f| File.directory?(f) }

          @project_file_count = files.size
          @project_mtime = files.map { |x| File.mtime(x).to_i }.max

          Thread.new do
            # TODO instead of polling every second, should investigate using a FS event
            # monitor like fssm (https://github.com/ttilley/fssm). Would be both quicker 
            # and less resource intensive than polling
            while @should_monitor

              # only need to start scanning again 2 seconds after the last
              # request was serviced.
              reload_delay = (Time.now - @last_reload_time)
              if reload_delay > 2
                files = Dir.glob(@project_root / '**' / '*')
                # follow 1-level of symlinks
                files += Dir.glob(@project_root / '**' / '*' / '**' / '*')
                tmp_path = /^#{Regexp.escape(@project_root / 'tmp')}/
                files.reject! { |f| (f =~ tmp_path || File.directory?(f) || f =~ @project.nomonitor_pattern) }

                cur_file_count = files.size
                cur_mtime = files.map { |x| File.mtime(x).to_i }.max

                if (@project_file_count != cur_file_count) || (@project_mtime != cur_mtime)
                  SC.logger.info "Detected project change.  Will rebuild manifest"
                  @project_did_change = true
                  @project_file_count = cur_file_count
                  @project_mtime = cur_mtime
                  # place for some extra project maintainen
                  extra_action = @project.monitor_proc
                  extra_action.call if (extra_action && extra_action.respond_to?(:call))
                end
              end

              sleep(2)
            end
          end
        end
      end

      def stop_monitor!
        @should_monitor = false
      end

      def target_for(url)

        # get targets
        targets = project.targets.values.dup
        targets.each { |t| t.prepare! }

        # split the url into parts.  pop parts until we find a matching
        # target.  This ensures that we end up with the deepest matching
        # target.
        url_parts = url.split '/'
        ret = nil

        while url_parts.size>0 && ret.nil?
          url = url_parts.join '/'
          ret = targets.find { |t| t[:url_root] == url || t[:index_root] == url }
          url_parts.pop
        end
        return ret
      end

      # Helper method.  This will normalize a URL into one that can map
      # directly to an entry in the bundle.  If the URL is of a format that
      # cannot be converted, returns the url.  In particular, this will look
      # for all the different ways you can request an index.html file and
      # convert it to a canonical form
      #
      # Returns the normalized url, the language extracted from the url and
      # a boolean indicating whether the url is considered cacheable or not.
      # any url beginning with the target's url_root is considered cacheable
      # and will therefore be returned with an expires <10years> header set.
      #
      # === Params
      #  url:: the url to normalize
      #  target:: the suspected target url
      #
      # === Returns
      #  [normalized url, matched language, cacheable]
      #
      def normalize_url(url, target)

        cacheable = true

        # match
        # /foo - /foo/index.html
        # /foo/en - /foo/en/index.html
        # /foo/en/build_number - /foo/en/build_number/index.html
        # /foo/en/CURRENT/resource-name
        matched = url.match(/^#{Regexp.escape target[:index_root]}(\/([^\/\.]+))?(\/([^\/\.]+))?(\/(.*))?$/)
        unless matched.nil?
          matched_language = matched[2] || target.config[:preferred_language]

          matched_build_number = matched[4]
          if matched_build_number.blank? || matched_build_number == 'current'
            matched_build_number = target[:build_number]
          end

          resource_name = matched[6]
          resource_name = 'index.html' if resource_name.blank?

          # convert to url root based
          url = [target[:url_root], matched_language, matched_build_number,
                 resource_name] * '/'
          cacheable = false # index_root based urls are not cacheable

        # otherwise, just get the language -- url_root-based urls must be
        # fully qualified
        else
          matched = url.match(/^#{Regexp.escape  target[:url_root]}\/([^\/\.]+)/)
          matched_language = matched ? matched[1] : nil
        end

        return [url, matched_language, cacheable]
      end

      # Returns the mime type.  Basically this is the Rack mime mapper with
      # a few bug fixes.
      def mime_type(build_path, custom = {})
        ext = File.extname(build_path)

        case ext
        when '.js'
          'text/javascript'
        when '.ttf'
          'font/ttf'
        else
          custom[ext] || ::Rack::Mime.mime_type(ext, 'text/plain')
        end

      end

    end

  end
end
