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
      
      # When you create a new builder, pass in one or more projects you want
      # the builder to monitor for changes.
      def initialize(project)
        @project = project
        @last_reload_time = Time.now 
      end
      
      # Main entry point for this Rack application.  Returns 404 if no
      # matching entry could be found in the project.
      def call(env)
        mutex.synchronize { _call(env) }
      end
      
      def _call(env)
        reload_project! # if needed

        # collect some standard info
        url = env['PATH_INFO']
        
        # look for a matching target
        target = target_for(url)
        return not_found("No matching target") if target.nil?
        
        # normalize url to resolve to entry & extract the language
        url, language = normalize_url(url, target)
        return not_found("Target requires language") if language.nil?
        
        # lookup manifest
        language = language.to_s.downcase.to_sym # normalize
        manifest = target.manifest_for(:language => language).build!
        
        # lookup entry by url
        unless entry = manifest.entries.find { |e| e.url == url }
          return not_found("No matching entry in target")
        end
        
        # Clean the entry so it will rebuild if we are serving an html file
        entry.clean! if entry.filename =~ /.html$/
        
        # Now build entry and return a file object
        build_path = entry.build!.build_path
        unless File.file?(build_path) && File.readable?(build_path)
          return not_found("File could not build (entry: #{entry.filename} - build_paht: #{build_path}")
        end
        
        SC.logger.info "Serving #{target.target_name.to_s.sub(/^\//,'')}:#{entry.filename}"

        # define response headers
        file_size = File.size(build_path)
        headers = {
          "Last-Modified"  => File.mtime(build_path).httpdate,
          "Content-Type"   => ::Rack::Mime.mime_type(File.extname(build_path), 'text/plain'),
          "Content-Length" => file_size.to_s
        }
        [200, headers, File.open(build_path, 'rb')]
      end
      
      attr_reader :project
      
      protected
      
      # Mutex used to ensure project building and other important tasks
      # are performed synchronously
      def mutex; @mutex ||= Mutex.new; end
      
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
        # don't reload if no project or is disabled
        return if @project.nil? || !@project.config.reload_project
        
        # reload at most every 5 sec
        return if (Time.now - @last_reload_time) < 5
        
        @last_reload_time = Time.now
        
        @project.reload!
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
          ret = targets.find { |t| t.url_root == url || t.index_root == url }
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
      # ==== Params
      # url<String>:: The URL
      #
      def normalize_url(url, target)

        # Parse the URL
        matched = url.match(/^#{Regexp.escape target.index_root}(\/([^\/\.]+))?(\/([^\/\.]+))?(\/|(\/index\.html))?$/)
        unless matched.nil?
          matched_language = matched[2] || target.config.preferred_language
          matched_build_number = matched[4] || target.build_number || 'current'
          url = [target.url_root, 
            matched_language, matched_build_number,
            'index.html'] * '/'
        else
          matched = url.match(/^#{Regexp.escape  target.url_root}\/([^\/\.]+)/)
          matched_language = matched ? matched[1] : nil
        end

        return [url, matched_language]
      end
      
      
    end
    
  end
end