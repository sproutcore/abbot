config :all,
  :url_prefix => 'static',
  
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
  :allow_nested_targets => true
    
