# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

# Rakefile used to build the SproutCore Gem.  Requires Jeweler to function.

ROOT_PATH = File.dirname(__FILE__)

# files to ignore changes in
IGNORE_CHANGES = %w[.gitignore .gitmodules .DS_Store .gemspec VERSION.yml ^pkg ^tmp ^coverage]

################################################
## LOAD DEPENDENCIES
##
begin
  require 'rubygems'
  require 'jeweler'
  require 'extlib'
  require 'spec/rake/spectask'

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
  gemspec.authors = 'Sprout Systems, Inc.  Apple Inc. and contributors'
  gemspec.email = 'contact@sproutcore.com'
  gemspec.homepage = 'http://www.sproutcore.com/sproutcore'
  gemspec.summary = "SproutCore is a platform for building native look-and-feel applications on  the web"
  
  gemspec.add_dependency 'rack', '>= 0.9.1'
  gemspec.add_dependency 'json_pure', ">= 1.1.0"
  gemspec.add_dependency 'extlib', ">= 0.9.9"
  gemspec.add_dependency 'erubis', ">= 2.6.2"
  gemspec.add_dependency 'thor', '>= 0.11.7'
  gemspec.add_development_dependency 'jeweler', ">= 1.0.1"
  gemspec.rubyforge_project = "sproutcore"
  gemspec.extra_rdoc_files.include *%w[History.txt README.txt]
    
  gemspec.files.include *%w[.htaccess frameworks/sproutcore/**/*]
  gemspec.files.exclude *%w[^coverage/ .gitignore .gitmodules .DS_Store tmp .hashinfo .svn .git]
  
  gemspec.description = File.read(ROOT_PATH / 'README.txt')
end

Jeweler::RubyforgeTasks.new do |rubyforge|
  rubyforge.doc_task = "rdoc"
end

################################################
## CORE TASKS
##
  
desc "performs an initial setup on the tools.  Installs gems, init submodules"
task :init do
  $stdout.puts "Installing gems (may ask for password)"
  `sudo gem install rack jeweler json_pure extlib erubis thor`
  
  $stdout.puts "Setup submodules"
  `git submodule update --init`
end

desc "computes the current hash of the code.  used to autodetect build changes"
task :hash_content do
  
  require 'yaml'
  require 'digest/md5'

  ignore = IGNORE_CHANGES.map do |x| 
    if x =~ /^\^/
      /^#{Regexp.escape(ROOT_PATH / x[1..-1])}/
    else
      /#{Regexp.escape(x)}/
    end
  end

  # First, get the hashinfo if it exists.  use this to decide if we need to
  # rehash
  hashinfo_path = ROOT_PATH / '.hashinfo.yml'
  hash_date = 0
  hash_digest = nil
  
  if File.exist?(hashinfo_path)
    yaml = YAML.load_file(hashinfo_path)
    hash_date = yaml['date'] || yaml[:date] || hash_date
    hash_digest = yaml['digest'] || yaml[:digest] || hash_digest
  end
  
  # paths to search  
  paths = Dir.glob(File.join(ROOT_PATH, '**', '*')).reject do |path|
    File.directory?(path) || (ignore.find { |i| path =~ i })
  end
  
  cur_date = 0
  paths.each do |path|
    mtime = File.mtime(path)
    mtime = mtime.nil? ? 0 : mtime.to_i
    puts "detected file change: #{path.gsub(ROOT_PATH,'')}" if mtime > hash_date
    cur_date = mtime if mtime > cur_date
  end
  
  if hash_digest.nil? || (cur_date != hash_date) 
    digests = paths.map do |path|
      Digest::SHA1.hexdigest(File.read(path))
    end
    digests.compact!
    hash_digest = Digest::SHA1.hexdigest(digests.join)
  end
  hash_date = cur_date
  
  # write cache
  File.open(hashinfo_path, 'w+') do |f|
    YAML.dump({ :date => hash_date, :digest => hash_digest }, f)
  end

  # finally set the hash
  CONTENT_HASH = hash_digest
  puts "CONTENT_HASH = #{CONTENT_HASH}"
end
  
desc "updates the VERSION file, bumbing the build rev if the current commit has changed"
task :update_version => 'hash_content' do

  path = ROOT_PATH / 'VERSION.yml'
 
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
    rev   = yaml['digest'] || yaml[:digest] || rev
  end
 
  build += 1 if rev != CONTENT_HASH  #increment if needed
  rev = CONTENT_HASH
  
  puts "write version #{[major, minor, build].join('.')} => #{path}"
  File.open(path, 'w+') do |f|
    YAML.dump({ 
      :major => major, :minor => minor, :patch => build, :digest => rev 
    }, f)
  end
end

def fixup_gemspec
  from_path = ROOT_PATH / 'sproutcore.gemspec'
  to_path = ROOT_PATH / 'sproutcore-abbot.gemspec'
  
  if File.exists?(from_path)
    FileUtils.rm(to_path) if File.exists?(to_path)
    FileUtils.cp(from_path, to_path)
  end
end

# Extend install to cleanup the generate and cleanup the gemspec afterwards
task :build => 'gemspec:generate' do
  fixup_gemspec
end

#task "gemspec:generate" => 'git:verify_clean'

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
    %w(abbot frameworks/sproutcore lib/thor).each do |repo_name|
      if repo_name == 'abbot'
        path = ROOT_PATH
      else
        path = File.join(repo_name.split('/').unshift(ROOT_PATH))
      end

      result = `cd #{path}; git status`
      if !(result =~ /nothing to commit \(working directory clean\)/)
        $stderr.puts "\nFATAL: Cannot complete task: changes are still pending in the '#{repo_name}' repository."
        $stderr.puts "       Commit your changes to git to continue.\n\n"
        exit(1)
      end
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
task 'gemspec:generate' => :update_version
task 'rubyforge:setup' => :update_version

Spec::Rake::SpecTask.new


# EOF
