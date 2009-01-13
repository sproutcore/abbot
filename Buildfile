# Import all build tasks
import *Dir.glob(File.join(File.dirname(__FILE__), 'buildtasks', '**', '*.rake'))

config :all,

  # REQUIRED CONFIGS 
  # You will not usually need to override these configs, but the code assumes
  # they will be present, so you must support them.
  :build_prefix => 'public',
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
  
  :preferred_language => :en    

namespace :manifest do

  # This task is invoked by the build system whenever it needs to generate
  # a manifest.  If you supply a manifest file to a build process, the file
  # will be used directly and this task will not be invoked.
  #
  # The default version of this tool will execute the "sc-manifest build" tool
  # and load the results into the manifest. (Actually it will invoke the tool
  # internally, but the effect is the same)
  #
  # You can override this task to call out to your own tool to process the
  # manifest.
  #
  task :prepare do
    SC::Tools::Manifest.build(MANIFEST)
  end
  
end
