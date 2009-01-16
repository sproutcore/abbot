# Import all build tasks
import *Dir.glob(File.join(File.dirname(__FILE__), 'buildtasks', '**', '*.rake'))

mode :all do
  config :all,

    # REQUIRED CONFIGS 
    # You will not usually need to override these configs, but the code 
    # assumes they will be present, so you must support them.
    :build_prefix => 'tmp/build',
    :staging_prefix => 'tmp/staging',
    :url_prefix    => 'static',
  
    # Defines the directories that may contain targets, and maps them to a 
    # target type.  When a project tries to find all of the targets in a 
    # project, it will use this map to find them.
    :target_types => { 
      :apps       => :app, 
      :clients    => :app, 
      :frameworks => :framework,
    },
  
    # Allows the target to have other targets nested inside of it.  Override 
    # this in your target Buildfile to disable nesting.
    :allow_nested_targets => true,

    # The default preferred language.  Assets will be pulled from this 
    # language unless otherwise specified.
    :preferred_language => :en,
    
    # Do not include fixtures in built project.
    :load_fixtures => false,
    
    # Do not include debug directory in built project
    :load_debug => false,
    
    # Do not build tests.
    :load_tests => false
end


mode :debug do
  config :all,
  
    # in debug mode, load fixtures and debug code
    :load_fixtures => true,
    :load_debug    => true,
    :load_tests    => true
end

