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

depend_on 'extlib', ">= 0.9.9"
depend_on 'rack', '>= 0.9.1'
depend_on 'erubis', ">= 2.6.2"
depend_on 'json_pure', ">= 1.1.0"

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
PROJ.exclude << '^coverage/' << '\.gitignore' << '\.gitmodules'

# For development builds add timestamp to the version number to auto-version 
# development gems.
PROJ.version += ".#{Time.now.strftime("%Y%m%d%H%M%S")}" if !ENV['VERSION'] 
  
# EOF
