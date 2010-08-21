# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked to actually render a single HTML file.  Works much like a 
# build task but also expects a CONTEXT variable that contains the html 
# context.
namespace :render do

  desc "renders erubis including .rhtml and .html.erb files"
  task :erubis do |task, env|
    env[:context].compile SC::RenderEngine::Erubis.new(env[:context]), env[:src_path]
  end
  
  desc "renders haml files"
  task :haml do |task, env|
    env[:context].compile SC::RenderEngine::Haml.new(env[:context]), env[:src_path]
  end
  
end
