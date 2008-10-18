############################################################
## Configure Merb
##

Merb::Router.prepare { |r| r.connect_clients('/') }

Merb::Config.use { |c|
  c[:framework]           = {}
  c[:session_store]       = 'none'
  c[:exception_details]   = true
  c[:reload_classes]      = false
  c[:use_mutex]           = false
  c[:log_auto_flush]      = true
  c[:log_level]           = :warn
  c[:disabled_components] = [:initfile]
}

############################################################
## Register Exception Handler
##

class Exceptions < ::Merb::Controller
  def base
    params[:exception].to_s
  end

  def not_found
    return "<h1>404</h1>NOT FOUND"
  end
end