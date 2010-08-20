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

# Get the DISTRIBUTION info
require 'yaml'

DIST_PATH = File.expand_path(File.join(ROOT_PATH, 'DISTRIBUTION.yml'))
DIST = YAML.load File.read(DIST_PATH)

LOCAL_DIST_PATH = File.expand_path(File.join(ROOT_PATH, 'LOCAL.yml'))
if File.exists? LOCAL_DIST_PATH

  # merged each item in the top level hash.  This allows for key-by-key
  # overrides
  (YAML.load(File.read(LOCAL_DIST_PATH)) || {}).each do |key, opts|
    if DIST[key]
      DIST[key].merge! opts
    else
      DIST[KEY] = opts
    end
  end

  puts "Using local overrides for distribution"
end

REMOTE_NAME = 'dist' # used by git

# Make empty to not use sudo
SUDO = 'sudo'

################################################
## LOAD DEPENDENCIES
##

# Core dependencies. Just warn if these are not available
begin
  require 'rubygems'
  require 'extlib'
  require 'fileutils'
  require 'spec/rake/spectask'

  $:.unshift(ROOT_PATH / 'lib')

  require 'sproutcore'

rescue LoadError => e
  $stderr.puts "WARN: some required gems are not installed (try rake init to setup)"
  $stderr.puts e
end


################################################
## JEWELER PROJECT DESCRIPTION
##

namespace :gem do
  task :clean do
    system "rm *.gem"
  end

  desc "build the sproutcore gem"
  task :build => :clean do
    system "gem build sproutcore.gemspec"
  end

  desc "install the sproutcore gem to the system"
  task :install => :build do
    gem = Dir["*.gem"][0]
    system "gem install #{gem}"
  end

  desc "push the sproutcore gem to rubygems.org"
  task :push => :build do
    gem = Dir["*.gem"][0]
    system "gem push #{gem}"
  end
end

################################################
## CORE TASKS
##

# git helper used to run git from within rake.
def git(path, cmd, log=true)
  $stdout.puts("#{path.sub(ROOT_PATH, '')}: git #{cmd}") if log
  git_path = path / '.git'
  git_index = git_path / 'index'

  # The env can become polluted; breaking git.  This will avoid that.
  %x[GIT_DIR=#{git_path}; GIT_WORK_TREE=#{path}; GIT_INDEX_FILE=#{git_index}; git #{cmd}]
end


desc "performs an initial setup on the tools.  Installs gems, checkout"
task :init => [:install_gems, 'dist:init']

desc "verifies that all required gems are installed"
task :install_gems do
  $stdout.puts "Installing gems (may ask for password)"

  gem_names = %w(rack json json_pure extlib erubis thor jeweler gemcutter rspec)
  gem_install = []
  gem_update = []

  # detect which ones are installed and update those
  gem_names.each do |name|
    if %x[gem list #{name}] =~ /#{Regexp.escape(name)} \(/
      gem_update << name
    else
      gem_install << name
    end
  end

  $stdout.puts "installing gems #{gem_install * ' '}"  if gem_install.size>0
  $stdout.puts "updating gems #{gem_update * ' '}"  if gem_update.size>0

  # install missing gems - updating known gems
  # this is faster than just installing all gems
  system %[#{SUDO} gem install #{gem_install * ' '}]
  system %[#{SUDO} gem update #{gem_update * ' '}]
end

namespace :dist do

  desc "checkout any frameworks in the distribution"
  task :init do
    $stdout.puts "Setup distribution"

    DIST.each do |rel_path, opts|
      path = ROOT_PATH / rel_path
      repo_url = opts['repo']
      dist_branch = opts['branch'] || 'master'

      # if the .git repository does not exist yet, create it
      if !File.exists?(path / ".git")
        $stdout.puts "  Creating repo for #{rel_path}"
        FileUtils.mkdir_p path

        $stdout.puts "\n> git clone #{repo_url} #{path}"
        system "GIT_DIR=#{path / '.git'}; GIT_WORK_TREE=#{path}; git init"
      end

      # if git exists, make sure a "dist" remote exists and matches the named
      # remote
      remote = git(path, 'remote -v').split("\n").find do |l|
        l =~ /^#{REMOTE_NAME}.+\(fetch\)/
      end

      if remote
        cur_repo_url = remote.match(/^#{REMOTE_NAME}(.+)\(fetch\)/)[1].strip
        if (cur_repo_url != repo_url)
          $stdout.puts "ERROR: #{rel_path} has a 'dist' remote pointing to a different repo.  Please remove the 'dist' remote and try again"
          exit(1)
        else
          $stdout.puts "Found #{rel_path}:dist => #{repo_url}"
        end

      # remote does not yet exist, add it...
      else
        $stdout.puts git(path,"remote add dist #{repo_url}")
      end

      $stdout.puts git(path, "fetch dist")

      # Make sure a "dist" branch exists..  if not checkout against the
      # dist branch
      if git(path, 'branch') =~ /dist\n/
        $stdout.puts "WARN: #{rel_path}:dist branch already exists.  delete branch and try again if you aren't sure it is setup properly"
      else
        git(path,"branch dist remotes/dist/#{dist_branch}")
      end

      git(path, "checkout dist")

    end
  end

  desc "Make sure each repository in the distribute is set to the target remote branch and up-to-date"
  task :update => 'dist:init' do
    $stdout.puts "Setup distribution"

    DIST.each do |rel_path, opts|
      path = ROOT_PATH / rel_path
      branch = opts['branch'] || 'master'

      if File.exists?(path / ".git")

        $stdout.puts "\n> git checkout dist"
        $stdout.puts git(path, "checkout dist")

        $stdout.puts "\n> git fetch dist"
        $stdout.puts git(path, 'fetch dist')

        $stdout.puts "\n> git rebase remotes/dist/#{branch}"
        $stdout.puts git(path, "rebase remotes/dist/#{branch}")

      else
        $stdout.puts "WARN: cannot fix version for #{rel_path}"
      end

    end
  end

  desc "make the version of each distribution item match the one in VERSION"
  task :freeze => 'dist:init' do
    $stdout.puts "Setup distribution"

    # Use this to get the commit hash
    version_file = ROOT_PATH / 'VERSION.yml'
    if File.exist?(version_file)
      versions = YAML.load File.read(version_file)
      versions = (versions['dist'] || versions[:dist]) if versions
      versions ||= {}
    end

    DIST.each do |rel_path, opts|
      path = ROOT_PATH / rel_path

      if File.exists?(path / ".git") && versions[rel_path]
        sha = versions[rel_path]

        $stdout.puts "\n> git fetch"
        $stdout.puts git(path, 'fetch')

        if sha
          $stdout.puts "\n> git checkout #{sha}"
          $stdout.puts git(path, "checkout #{sha}")
        end

      else
        $stdout.puts "WARN: cannot fix version for #{rel_path}"
      end

    end
  end

end

namespace :release do

  desc "tags the current repository and any distribution repositories.  if you can push to distribution, then push tag as well"
  task :tag => :update_version do
    tag_name = "REL-#{RELEASE_VERSION}"
    DIST.keys.push('abbot').each do |rel_path|
      full_path = rel_path=='abbot' ? ROOT_PATH : (ROOT_PATH / rel_path)
      git(full_path, "tag -f #{tag_name}")
    end
  end

  task :push_tags => :tag do
    tag_name = "REL-#{RELEASE_VERSION}"
    DIST.keys.push('abbot').each do |rel_path|
      full_path = rel_path=='abbot' ? ROOT_PATH : (ROOT_PATH / rel_path)
      git(full_path, "push origin #{tag_name}")
    end
  end


  desc "prepare release.  verify clean, update version, tag"
  task :prepare => ['git:verify_clean', :update_version, :tag, :push_tags]

  desc "release to rubyforge for old skool folks"
  task :rubyforge => [:prepare, 'rubyforge:release']

  desc "release to gemcutter for new skool kids"
  task :gemcutter => [:prepare, 'gemcutter:release']

  desc "one release to rule them all"
  task :all => [:prepare, 'release:gemcutter']

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
    $stdout.puts "detected file change: #{path.gsub(ROOT_PATH,'')}" if mtime > hash_date
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
  $stdout.puts "CONTENT_HASH = #{CONTENT_HASH}"
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
  dist  = {}

  if File.exist?(path)
    yaml = YAML.load_file(path)
    major = yaml['major'] || yaml[:major] || major
    minor = yaml['minor'] || yaml[:minor] || minor
    build = yaml['patch'] || yaml[:patch] || build
    rev   = yaml['digest'] || yaml[:digest] || rev
  end

  build += 1 if rev != CONTENT_HASH  #increment if needed
  rev = CONTENT_HASH

  # Update distribution versions
  DIST.each do |rel_path, ignored|
    dist_path = ROOT_PATH / rel_path
    if File.exists?(dist_path)
      dist_rev = git(dist_path, "log HEAD^..HEAD")
      dist_rev = dist_rev.split("\n").first.scan(/commit ([^\s]+)/)
      dist_rev = ((dist_rev || []).first || []).first

      if dist_rev.nil?
        $stdout.puts " WARN: cannot find revision for #{rel_path}"
      else
        dist[rel_path] = dist_rev
      end
    end
  end

  $stdout.puts "write version #{[major, minor, build].join('.')} => #{path}"
  File.open(path, 'w+') do |f|
    YAML.dump({
      :major => major,
      :minor => minor,
      :patch => build,
      :digest => rev,
      :dist   => dist
    }, f)
  end

  RELEASE_VERSION = "#{major}.#{minor}.#{build}"

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
    DIST.keys.push('abbot').each do |repo_name|
      full_path = repo_name=='abbot' ? ROOT_PATH : (ROOT_PATH / repo_name)

      result = git(full_path, 'status')

      if !(result =~ /nothing to commit \(working directory clean\)/)
        if (repo_name != 'abbot') ||
           (!(result =~ /#\n#\tmodified:   VERSION.yml\n#\n/))
          $stderr.puts "\nFATAL: Cannot complete task: changes are still pending in the '#{repo_name}' repository."
          $stderr.puts "       Commit your changes to git to continue.\n\n"
          exit(1)
        end
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
