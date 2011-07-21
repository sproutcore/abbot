# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  class Tools

    desc "server", "Starts the development server"
    method_options  :daemonize  => false,
                    :pid        => :string,
                    :port       => :string,
                    :host       => :string,
                    :irb        => false,
                    :filesystem => true
    
    method_option :whitelist, :type => :string,
      :desc => "The whitelist to use when building. By default, Whitelist (if present)"
    method_option :blacklist, :type => :string,
      :desc => "The blacklist to use when building. By default, Blacklist (if present)"

    
    method_option :allow_from_ips,
      :default => "127.0.0.1",
      :desc => "One or more (comma-separated) masks to accept requests from. " +
        "For example: 10.*.*.*,127.0.0.1"
    def server
      if options.help
        help('server')
        return
      end
      
      prepare_mode!('debug') # set mode again, using debug as default

      SC.env[:build_prefix]   = options[:buildroot] if options[:buildroot]
      SC.env[:staging_prefix] = options[:stageroot] if options[:stageroot]
      SC.env[:whitelist_name] = options.whitelist
      SC.env[:blacklist_name] = options.blacklist

      # get project and start service.
      project = requires_project!

      # start shell if passed
      if options[:irb]
        require 'irb'
        require 'irb/completion'
        if File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end

        SC.project = project
        SC.logger << "SproutCore v#{SC::VERSION} Interactive Shell\n"
        SC.logger << "SC.project = #{project.project_root}\n"
        ARGV.clear # do not pass onto IRB
        IRB.start
      else
        SC.logger << "SproutCore v#{SC::VERSION} Development Server\n"
        begin
          SC::Rack::Service.start(options.merge(:project => project))
        rescue => e
          if e.message =~ /no acceptor/
            raise "No acceptor. Most likely the port is already in use. Try using --port to specify a different port."
          else
            raise e
          end
        end
      end
    end

  end
end
