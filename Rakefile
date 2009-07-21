# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple, Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

# Rakefile used to build the SproutCore Gem.  Requires Jeweler to function.

ROOT_PATH = File.dirname(__FILE__)

################################################
## LOAD DEPENDENCIES
##
begin
  require 'jeweler'
  require 'extlib'

  $:.unshift(ROOT_PATH / 'lib')
  require 'sproutcore'

rescue LoadError => e
  $stderr.puts "WARN: some required gems are not installed (try rake init to setup)"
end


################################################
## PROJECT DESCRIPTION
##

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
  gemspec.add_development_dependency 'jeweler', ">= 1.0.1"
  gemspec.rubyforge_project = "sproutcore"
  gemspec.files.exclude *%w[^coverage/ .gitignore .gitmodules .DS_Store]
  gemspec.extra_rdoc_files.include *%w[History.txt README.txt]
  
  gemspec.description = File.read(ROOT_PATH / 'README.txt')
end

################################################
## CORE TASKS
##
  
desc "performs an initial setup on the tools.  Installs gems, init submodules"
task :init do
  $stdout.puts "Installing gems (may ask for password)"
  `sudo gem install rack jeweler json_pure extlib erubis`
  
  $stdout.puts "Setup submodules"
  `git submodule update --init`
end

desc "updates the VERSION file, bumbing the build rev if the current commit has changed"
task :update_version => 'git:collect_commit' do

  path = ROOT_PATH / 'VERSION.yaml'
 
  require 'yaml'
 
  # first, load the current yaml if possible
  major = 1
  minor = 0
  build = 99
  rev   = '-0-'
  
  if File.exist?(path)
    yaml = YAML.load_file(path)
    major = yaml['major'] || yaml[:major] || major
    minor = yaml['minor'] || yaml[:minor] || minor
    build = yaml['patch'] || yaml[:patch] || build
    rev   = yaml['commit'] || yaml[:commit] || rev
  end
 
  build += 1 if rev != COMMIT_ID  #increment if needed
  rev = COMMIT_ID
  
  puts "write version => #{path}"
  File.open(path, 'w+') do |f|
    YAML.dump({ 
      :major => major, :minor => minor, :patch => build, :commit => rev 
    }, f)
  end
end

def fixup_gemspec
  from_path = ROOT_PATH / 'sproutcore.gemspec'
  to_path = ROOT_PATH / 'sproutcore-abbot.gemspec'
  
  if File.exists?(from_path)
    FileUtils.rm(to_path) if File.exists?(to_path)
    FileUtils.move(from_path, to_path)
  end
end

# Extend install to cleanup the generate and cleanup the gemspec afterwards
task :build => 'gemspec:generate' do
  fixup_gemspec
end

# Extend gemspec to rename afterware
task :gemspec do
  
  fixup_gemspec
end

desc "cleanup the pkg dir" 
task :clean do
  path = ROOT_PATH / 'pkg'
  FileUtils.rm_r(path) if File.directory?(path)
  `rm #{ROOT_PATH / '*.gem'}`
end

namespace :git do
  
  desc "verifies there are no pending changes to commit to git"
  task :verify_clean do
    result = `cd #{ROOT_PATH}; git status`
    if !(result =~ /nothing to commit \(working directory clean\)/)
      $stderr.puts "\nFATAL: Cannot complete task with changes pending."
      $stderr.puts "       Commit your changes to git to continue.\n\n"
      exit(1)
    end
  end
  
  desc "Collects the current SHA1 commit hash into COMMIT_ID"
  task :collect_commit do
    log = `git log HEAD^..HEAD`
    COMMIT_ID = log.split("\n").first.match(/commit ([\w]+)/).to_a[1]
    if COMMIT_ID.empty?
      $stderr.puts "\nFATAL: Cannot discover current commit id"
      exit(1)
    else
      $stdout.puts "COMMIT_ID = #{COMMIT_ID}"
    end
  end
  
end

# Write a new version everytime we generate
task 'gemspec:generate' => :write_version

# EOF
