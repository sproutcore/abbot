# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC
  module Rack

    # Configures a standard set of Rack adaptors for serving SproutCore apps.
    # Based on your config settings, this will configure appropriate 
    # middlewear apps for each incoming project.  Requests are then cascaded
    # through the projects to find one that can service the request.
    #
    class Service
      
      cattr_accessor :filesystem
      
      # Convenience method to start the rack service as a server.  You must
      # pass at least a :project => foo, or :projects => [foo, bar] option
      # to this method, but you may also pass a number of other config optios
      # including:
      #
      # === Options
      #  :host:: the hostname to listen on (default 0.0.0.0)
      #  :port:: the portname to listen on (default 4020)
      #  :daemonize:: if true, service will be run as daemon
      #  :pid:: if daemonizing, this is the path of the file to write pid to
      #
      def self.start(opts = {})
        
        # load rack
        begin
          require 'rack'
        rescue LoadError => e
          gem 'rack'
          require 'rack'
        end
        
        # Guess.
        if ENV.include?("PHP_FCGI_CHILDREN")
          server = ::Rack::Handler::FastCGI

          # We already speak FastCGI
          options.delete :File
          options.delete :Port
        elsif ENV.include?("REQUEST_METHOD")
          server = ::Rack::Handler::CGI
        else
          begin
            server = ::Rack::Handler::Mongrel
          rescue LoadError => e
            server = ::Rack::Handler::WEBrick
          end
        end
        
        opts[:Filesystem] ||= opts[:filesystem] || false # allow either case
        self.filesystem = opts[:Filesystem]
        
        projects = opts.delete(:projects) || [opts.delete(:project)].compact
        app = self.new(*projects)
        
        opts[:Host] ||= opts[:host] # allow either case.
        opts[:Port] ||= opts[:port] || '4020'
        
        # If daemonize is set, do it...
        if opts[:daemonize]
          SC.logger.info "Daemonizing..."
          pid = opts[:pid]
          
          if RUBY_VERSION < "1.9"
            return if fork
            Process.setsid
            return if fork
            Dir.chdir "/"
            File.umask 0000
            STDIN.reopen "/dev/null"
            STDOUT.reopen "/dev/null", "a"
            STDERR.reopen "/dev/null", "a"
          else
            Process.daemon
          end

          if pid
            File.open(pid, 'w'){ |f| f.write("#{Process.pid}") }
            at_exit { File.delete(pid) if File.exist?(pid) }
          end
        end
        
        SC.logger << "Starting server at http://#{opts[:Host] || '0.0.0.0'}:#{opts[:Port]} in #{SC.build_mode} mode\n"
        SC.logger << "To quit sc-server, press Control-C\n"
        server.run app, opts
      end
        
      def initialize(*projects)
        @projects = projects.flatten

        # Get apps for each project & cascade if needed
        @apps = @projects.map { |project| middleware_for(project) }
        @app = @apps.size == 1 ? @apps.first : ::Rack::Cascade.new(@apps)

        # Now put it behind some useful general optimizers...
        @app = ::Rack::Recursive.new(@app)
        @app = ::Rack::ConditionalGet.new(@app)
        #@app = ::Rack::Deflater.new(@app)
        
      end
      
      def call(env); @app.call(env); end
      
      # Construct new middleware for the named project
      def middleware_for(project)
        apps = []

        # setup some conditional items...
        config = project.config
        #if config.serve_test_runner || config.serve_docs
          apps << SC::Rack::Dev.new(project) 
        #end
        if project.buildfile.proxies.size > 0
          apps << SC::Rack::Proxy.new(project) 
        end

        # Add builder for the project itself
        apps  << SC::Rack::Builder.new(project)
        
        # serve files out of the public directory if serve_public is 
        # configures && the public directory exists
        if config.serve_public
          pubdir = File.join(project.project_root, 'public')
          apps  << ::Rack::File.new(pubdir) if File.directory?(pubdir)
        end
        
        if self.filesystem
          apps << SC::Rack::Filesystem.new(project)
        end
        
        # Wrap'em in a cascade if needed.  This will return the first
        # app that does not return nil
        app = apps.size == 1 ? apps.first : ::Rack::Cascade.new(apps) 
        
        # Add show exceptions handler if enabled
        app = ::Rack::ShowExceptions.new(app) if config.serve_exceptions
        
        return app # done!
      end
      
    end
  end
end