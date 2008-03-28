# Helpers are mostly borrowed from Rails 2.0.2 with some additional features specifically
# for building client-side JavaScript.
Dir.glob(File.join(File.dirname(__FILE__),'helpers','**','*.rb')).each { |x| require x }