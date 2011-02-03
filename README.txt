sproutcore - abbot
    by Charles Jolley and contributors
    http://www.sproutcore.com
    http://github.com/sproutit/sproutcore-abbot

== DESCRIPTION:

SproutCore is a platform for building native look-and-feel applications on 
the web.  This Ruby library includes a copy of the SproutCore JavaScript 
framework as well as a Ruby-based build system called Abbot.

Abbot is a build system for creating static web content.  You can supply Abbot with a collection of JavaScript, HTML, CSS and image files and it will 
combine the files into a bundle that are optimized for efficient, cached 
deliver directly from your server or using a CDN.

Some of the benefits of using Abbot versus assembling your own content 
include:

 * Easy maintenance.  Organize your source content in a way that is useful for 
   you without impacting performance on loaded apps.
 
 * Automatically versioned URLs. Serve content with long expiration dates
   while Abbot handles the cache invalidation for you.
 
 * Dependency management.  Divide your code into frameworks; load 3rd party
   libraries.  Abbot will make sure everything loads in the correct order.
   
 * Packing.  Combines JavaScript and CSS into single files to minimize the
   number of resources you download for each page.
  
Although Abbot is intended primarily for building Web applications that 
use the SproutCore JavaScript framework, you can also use it to efficiently build any kind of static web content, even if SproutCore is not involved.

Abbot can be used both directly from the command line or as a ruby library. 
  
== USING ABBOT WITH SPROUTCORE:

This gem includes both the Abbot build tools and a copy of the SproutCore
JavaScript framework.  You can use built-in commands to create, develop, 
build, and deploy SproutCore-based applications.

== USING ABBOT FROM SOURCE:

These steps will allow the use of a development release of abbot rather than an installed gem.

  1. Inside a empty project folder create a file named 'Gemfile' (no extension)

    Modify the file so that it contains:
      source "http://rubygems.org"
      gem "sproutcore", :git => "git://github.com/sproutcore/abbot.git"
      # if you want to use a version of abbot already checked out into your system rather than the remote repository
      # gem "sproutcore", :path => "/path/to/abbot"

  2. Install Abbot and its dependencies by running these commands

    $ sudo gem install bundler
    $ bundle install --binstubs

    This will install the Ruby 'bundler' gem (if it is not already), then add a 'bin' directory to your project containing executables like "sc-server".
    The bundle install command will take care of locating, installing and linking to either the remote git or locally installed version of abbot and dependencies.

  3. Init the Sproutcore project and start the server

    $ bin/sc-init .
    $ bin/sc-server

== KNOWN LIMITATIONS:

* Currently does not support sites using relative-links.  You must specify
  the absolute path you expect built targets to be hosted as.  

== SYNOPSIS:

To create a new project:

  sc-init my_app
  
To test said project:

  cd my_app
  sc-server
  open http://localhost:4020/my_app (in web browser)
  
Write code, refresh, debug.  Once you are ready to deploy, build your static
output using:

  cd my_app
  sc-build my_app -rc
  
Copy the resulting files found in my_app/tmp/build to your server and you are
deployed!

== REQUIREMENTS:

* Ruby 1.8.6 or later.  Ruby 1.9 is currently untested
* extlib 0.9.9 or later
* rack 0.9.1 or later
* erubis 2.6.2 or later
* json_pure 1.1.0 or later

== INSTALL:

sudo gem install sproutcore

== LICENSE:

Copyright (c) 2009 Apple Inc.  
Portions copyright (c) 2006-2011 Strobe Inc. and contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

SproutCore and the SproutCore logo are trademarks of Strobe Inc.
