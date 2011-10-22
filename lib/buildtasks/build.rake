# ===========================================================================
# SC::Target Buildtasks
# copyright 2011, Strobe Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.  You can also define new builders and assign them to
# manifest entries if you also override/extend manifest:build.
namespace :build do

  desc "copies a single resource"
  build_task :copy do |task, env|
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(env[:dst_path]))
    FileUtils.cp_r(env[:src_path], env[:dst_path])
  end

  desc "builds a single css files"
  build_task :css do |task, env|
    SC::Builder::Stylesheet.build env[:entry], env[:dst_path]
  end

  desc "builds an image file"
  build_task :image do |task, env|
    # by default, just copy images
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(env[:dst_path]))
    FileUtils.cp_r(env[:src_path], env[:dst_path])
  end

  desc "converts a Handlebars file to JavaScript"
  build_task :handlebars do |task, env|
    SC::Builder::Handlebars.build env[:entry], env[:dst_path]
  end

  desc "splits CSS files by rule count so IE doesn't crap out"
  build_task :split_css do |task, env|
    SC::Builder::SplitCSS.build env[:entry], env[:dst_path]
  end

  desc "builds a single sass file"
  build_task :sass do |task, env|
    SC::Builder::Sass.build env[:entry], env[:dst_path]
  end
  
  desc "builds a single scss (sass v3 syntax) file"
  build_task :scss do |task, env|
    SC::Builder::Sass.build env[:entry], env[:dst_path], :scss
  end

  desc "builds a single less file"
  build_task :less do |task, env|
    SC::Builder::Less.build env[:entry], env[:dst_path]
  end
  
  desc "builds a single javascript file"
  build_task :javascript do |task, env|
    SC::Builder::JavaScript.build env[:entry], env[:dst_path]
  end
  
  desc "builds a single json file"
  build_task :json do |task, env|
    SC::Builder::JSON.build env[:entry], env[:dst_path]
  end
  
  desc "builds an html file, possibly executing render tasks"
  build_task :html do |task, env|
    SC::Builder::Html.build env[:entry], env[:dst_path]
  end

  desc "builds a strings file for use by server-side processing"
  build_task :strings do |task, env|
    SC::Builder::Strings.build env[:entry], env[:dst_path]
  end
  
  desc "combines several source files into a single target, using the ordered_entries property if it exists"
  build_task :combine do |task, env|
    SC::Builder::Combine.build env[:entry], env[:dst_path]
  end
  
  desc "adds all the css and image files in the target to chance and lets it run on a per-target basis"
  build_task :chance do |task, env|
    SC::Builder::Chance.build env[:entry], env[:dst_path]
  end

  desc "extracts a file from the Chance entries"
  build_task :chance_file do |task, env|
    SC::Builder::ChanceFile.build env[:entry], env[:dst_path]
  end
  
  desc "wraps the entry into a string for prefetched modules"
  build_task :string_wrap do |task, env|
    SC::Builder::StringWrapper.build env[:entry], env[:dst_path]
  end

  namespace :minify do
    
    desc "Minifies a CSS file by invoking CSSmin"
    build_task :css do |task, env|
      SC::Builder::Minify.build env[:entry], env[:dst_path], :css
    end

    desc "minifies a JavaScript file by invoking the YUI compressor"
    build_task :javascript do |task, env|
      SC::Builder::Minify.build env[:entry], env[:dst_path], :javascript
    end
    
    desc "minifies a HTML file by invoking the HTML compressor"
    build_task :html do |task, env|
      SC::Builder::Minify.build env[:entry], env[:dst_path], :html
    end
    
    desc "minifies a Javascript file immediately by invoking the YUI compressor"
    build_task :inline_javascript do |task, env|
      SC::Builder::Minify.build env[:entry], env[:dst_path], :inline_javascript
    end
  end
  
  desc "builds a unit test"
  build_task :test do |task, env|
    SC::Builder::Test.build env[:entry], env[:dst_path]
  end

  desc "builds the unit test index, describing the installed unit tests"
  build_task :test_index do |task, env|
    SC::Builder::TestIndex.build env[:entry], env[:dst_path]
  end

  desc "builds the module_info.js file for a required framework"
  build_task :module_info do |task, env|
    SC::Builder::ModuleInfo.build env[:entry], env[:dst_path]
  end
  
end
