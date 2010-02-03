# ===========================================================================
# SC::Target Buildtasks
# copyright 2008, Sprout Systems, Inc. and Apple Inc. all rights reserved
# ===========================================================================

# Tasks invoked while building Target objects.  You can override these methods
# in your buildfiles.  You can also define new builders and assign them to
# manifest entries if you also override/extend manifest:build.
namespace :build do

  desc "copies a single resource"
  build_task :copy do
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(DST_PATH))
    FileUtils.cp_r(SRC_PATH, DST_PATH)
  end

  desc "builds a single css files"
  build_task :css do
    SC::Builder::Stylesheet.build ENTRY, DST_PATH
  end

  desc "builds a single sass file"
  build_task :sass do
    SC::Builder::Sass.build ENTRY, DST_PATH
  end
  
  desc "builds a single javascript file"
  build_task :javascript do
    SC::Builder::JavaScript.build ENTRY, DST_PATH
  end
  
  desc "builds an html file, possibly executing render tasks"
  build_task :html do
    SC::Builder::Html.build ENTRY, DST_PATH
  end

  desc "builds a strings file for use by server-side processing"
  build_task :strings do
    SC::Builder::Strings.build ENTRY, DST_PATH
  end
  
  desc "combines several source files into a single target, using the ordered_entries property if it exists"
  build_task :combine do
    SC::Builder::Combine.build ENTRY, DST_PATH
  end
  
  desc "generates an HTML5 manifest file for each built application"
  build_task :html5_manifest do
    SC::Builder::HTML5Manifest.build ENTRY, DST_PATH
  end
  
  namespace :minify do
    
    desc "Minifies a CSS file by invoking CSSmin"
    build_task :css do
      SC::Builder::Minify.build ENTRY, DST_PATH, :css
    end

    desc "minifies a JavaScript file by invoking the YUI compressor"
    build_task :javascript do
      SC::Builder::Minify.build ENTRY, DST_PATH, :javascript
    end
    
    desc "minifies a Javascript file immediately by invoking the YUI compressor"
    build_task :inline_javascript do
      SC::Builder::Minify.build ENTRY, DST_PATH, :inline_javascript
    end
    
  end
  
  desc "builds a unit test"
  build_task :test do
    SC::Builder::Test.build ENTRY, DST_PATH
  end

  desc "builds the unit test index, describing the installed unit tests"
  build_task :test_index do
    SC::Builder::TestIndex.build ENTRY, DST_PATH
  end
  
  desc "builds the bundle_loaded.js file for a framework"
  build_task :bundle_loaded do
    SC::Builder::BundleLoaded.build ENTRY, DST_PATH
  end
  
  desc "builds the bundle_info.js file for a required framework"
  build_task :bundle_info do
    SC::Builder::BundleInfo.build ENTRY, DST_PATH
  end
  
end