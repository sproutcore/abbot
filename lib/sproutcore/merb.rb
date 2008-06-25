# This module defines the SproutCore support for Merb applications.  To host a SproutCore
# app in your Merb application, simply add the following line to your router:
#
#  Merb::Router.prepare do |r|
#    r.connect_clients('/', LIBRARY_ROOT)
#  end
#
# The first parameter you pass is the URL you want SproutCore apps to be served from.  Anything
# URL beginning with this root will be automatically directed to the SproutCore build tools.
#
# The second parameter is an optional root path to the Library that you want hosted at that
# location.  If you do not pass this parameter then Merb.root will be used (which is what you
# usually want anyway.)
#

# Load Merb if it is available
begin
  require('merb-core')
rescue LoadError
end

# Load SproutCore Merb support if Merb meets minimum criteria
if defined?(Merb) && defined?(Merb::VERSION) && (Merb::VERSION.to_f >= 0.9)
  Dir.glob(File.join(File.dirname(__FILE__),'merb','**','*.rb')).each { |x| require(x) }
else
  puts "WARNING: sproutcore/merb required Merb 0.9.1 or later.  Module was not loaded."
end
