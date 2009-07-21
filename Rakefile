# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

# This Rakefile is used to build and distribute the SproutCore Gem.  It
# requires the "bones" gem to provide the rake tasks needed for release.

################################################
## LOAD BONES
##
begin
  require 'bones'
  Bones.setup
rescue LoadError
  puts "WARN: bones gem is required to build SproutCore Gem"
  #load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'sproutcore'

################################################
## DEPENDENCIES
##

depend_on 'rack', '>= 0.9.1'
depend_on 'json_pure', ">= 1.1.0"
depend_on 'extlib', ">= 0.9.9"
depend_on 'erubis', ">= 2.6.2"

################################################
## PROJECT DESCRIPTION
##

task :default => 'spec:specdoc'

PROJ.name = 'sproutcore'
PROJ.authors = 'Sprout Systems, Inc.  Apple, Inc. and contributors'
PROJ.email = 'contact@sproutcore.com'
PROJ.url = 'http://www.sproutcore.com/sproutcore'
PROJ.version = SC::VERSION
PROJ.rubyforge.name = 'sproutcore'
PROJ.ruby_opts = []
PROJ.spec.opts << '--color'
PROJ.exclude << '^coverage/' << '\.gitignore' << '\.gitmodules' << ".DS_Store"

# For development builds add timestamp to the version number to auto-version 
# development gems.
PROJ.version += ".#{Time.now.strftime("%Y%m%d%H%M%S")}" if !ENV['VERSION'] 

#VERSION = SC::VERSION

require 'jeweler'

Jeweler::Tasks.new do |gemspec|
  gemspec.name = 'sproutcore'
  gemspec.authors = 'Sprout Systems, Inc.  Apple, Inc. and contributors'
  gemspec.email = 'contact@sproutcore.com'
  gemspec.homepage = 'http://www.sproutcore.com/sproutcore'
  gemspec.summary = "SproutCore is a platform for building native look-and-feel applications on  the web"
  
  gemspec.add_dependency 'rack', '>= 0.9.1'
  gemspec.add_dependency 'json_pure', ">= 1.1.0"
  gemspec.add_dependency 'extlib', ">= 0.9.9"
  gemspec.add_dependency 'erubis', ">= 2.6.2"
  gemspec.add_development_dependency 'bones', ">= 2.5.1"
  gemspec.rubyforge_project = "sproutcore"
  gemspec.files.exclude *%w[^coverage/ .gitignore .gitmodules .DS_Store]
  
  #gemspec.rubyforge.name = 'sproutcore'
  #gemspec.ruby_opts = []
  #gemspec.spec.opts << '--color'
  #gemspec.exclude << '^coverage/' << '\.gitignore' << '\.gitmodules' << ".DS_Store"

  # For development builds add timestamp to the version number to auto-version 
  # development gems.
end
  
task :write_version do
  path = File.join(File.dirname(__FILE__), 'VERSION')
  puts "write version => #{path}"
  f = File.open(path, 'w')
  
  version = ENV['VERSION'] || "#{SC::VERSION}.#{Time.now.strftime("%Y%m%d%H%M%S")}" 
  
  f.write(version)
  f.close
end

task 'gemspec:generate' => :write_version

# EOF
