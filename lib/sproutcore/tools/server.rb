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
                    :filesystem => true,
                    :allow_from_ips        => :string,
                    :whitelist  => :string
    def server
      prepare_mode!('debug') # set mode again, using debug as default

      SC.env[:build_prefix]   = options[:buildroot] if options[:buildroot]
      SC.env[:staging_prefix] = options[:stageroot] if options[:stageroot]
      SC.env[:whitelist]      = options[:whitelist]

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
