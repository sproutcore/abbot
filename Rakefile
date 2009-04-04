# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'sproutcore'

depend_on 'extlib'
depend_on 'rack'
depend_on 'erubis'
depend_on 'json_pure'

task :default => 'spec:specdoc'

PROJ.name = 'sproutcore'
PROJ.authors = 'Sprout Systems, Inc.  Apple, Inc. and contributors'
PROJ.email = 'contact@sproutcore.com'
PROJ.url = 'http://www.sproutcore.com/sproutcore'
PROJ.version = SC::VERSION
PROJ.rubyforge.name = 'sproutcore'
PROJ.ruby_opts = []
PROJ.spec.opts << '--color'
PROJ.exclude << '^coverage/' << '\.gitignore' << '\.gitmodules'

# EOF
