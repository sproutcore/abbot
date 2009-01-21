# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple, Inc. all rights reserved
# ===========================================================================

# Tasks invoked to actually render a single HTML file.  Works much like a 
# build task but also expects a CONTEXT variable that contains the html 
# context.
namespace :render do

  desc "renders erubis including .rhtml and .html.erb files"
  task :erubis do
    CONTEXT.compile SC::RenderEngine::Erubis.new(CONTEXT), SRC_PATH
  end
  
  desc "renders haml files"
  task :haml do
    CONTEXT.compile SC::RenderEngine::Haml.new(CONTEXT), SRC_PATH
  end
  
end