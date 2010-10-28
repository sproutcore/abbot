require 'yaml'
module SproutCore
  # :stopdoc:
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR

  VERSION_PATH = File.join(PATH, '..', 'VERSION.yml')
  VERSION_INFO = YAML.load_file(VERSION_PATH)

  VERSION = [VERSION_INFO[:major], VERSION_INFO[:minor], VERSION_INFO[:patch]].join('.')
  # :startdoc:
end
