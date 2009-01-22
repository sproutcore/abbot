module SC
  class Tools
    
    desc "server [start|stop]", "Starts the development server"
    method_options  :daemonize => false,
                    :port      => :optional,
                    :host      => :optional
    def server(command='start')
      prepare_mode!('debug') # set mode again, using debug as default
      
      SC.env.build_prefix   = options.buildroot if options.buildroot
      SC.env.staging_prefix = options.stageroot if options.stageroot
      
      # get project and start service.
      project = requires_project!
      SC::Rack::Service.start(options.merge(:project => project))
    end
    
  end
end
