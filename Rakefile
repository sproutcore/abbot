require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

APP_ROOT = File.expand_path(File.dirname(__FILE__))

# Set directories you want ignored in the manifest.
IGNORE_DIRS = ['assets', 'pkg', 'samples', 'doc', 'log']

Dir['tasks/**/*.rake'].each { |rake| load rake }