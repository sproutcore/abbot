require File.expand_path("../lib/sproutcore/version", __FILE__)

desc "Information for setup"
task :default do

  puts <<END

===================================================
**********************WARNING**********************
===================================================

It is not recommended that you install Abbot
directly from git. Unless you are hacking on Abbot 
you should use the gem:
 
  gem install sproutcore

===================================================

To get the SproutCore framework, run

  git submodule init
  git submodule update

To update the gem:

  - Update VERSION.yml
  - Run `rake release:prepare` on Mac OS X or Linux
      This updates the CHANGELOGS for both framework and abbot,
      updates version numbers and tags them. It also builds and
      pushes gems. If you just want to see what it does, pass
      PRETEND=1 to make no actual changes.
      For best results you should have RVM with MRI Ruby and JRuby installed.
  - Once you have verified your changes, run `rake release:deploy`.
  - On Windows, update the repos and run `rake release:gems:deploy`
  - To create installer packages, run `rake pkg` on Mac OS X and Windows

END

end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
  if Rake.application.options.show_tasks
    puts "RSpec is not installed. Please install if you want to run tests."
  end
end

begin
  require 'packager/rake_task'

  Packager::RakeTask.new(:pkg) do |t|
    t.version = SproutCore::VERSION
    t.domain = "sproutcore.com"
    t.package_name = "SproutCore"
    t.bin_files = Dir['bin/*'].map{|p| File.basename(p) }
    t.resource_files = ["vendor", "VERSION.yml"]
  end
rescue LoadError
  if Rake.application.options.show_tasks
    puts "`gem install packager` for packaging tasks"
  end
end

### RELEASE TASKS ###

rvm_data = `rvm list` rescue nil
rvm_versions = rvm_data ? rvm_data.split("\n")[3..-1].map{|l| l[3..-1].split(" ")[0] } : []
rvm_mri = rvm_versions.select{|v| v =~ /^ruby-/ }[-1]
rvm_jruby = rvm_versions.select{|v| v =~ /^jruby-/ }[-1]

version = SproutCore::VERSION

namespace :release do

  def pretend?
    ENV['PRETEND']
  end

  namespace :framework do

    task :chdir do
      chdir File.expand_path('../lib/frameworks/sproutcore', __FILE__)
    end

    task :update do
      branch = `git describe --contains --all HEAD`
      puts "Checking out framework branch: #{branch}"
      unless pretend?
        Rake::Task["release:framework:chdir"].invoke
        system "git checkout #{branch}"
        system "git pull"
      end
    end

    task :changelog => :chdir do
      last_tag = `git describe --tags --abbrev=0`.strip
      puts "Getting Changes since #{last_tag}"

      cmd = "git log #{last_tag}..HEAD --format='* %s'"
      puts cmd

      changes = `#{cmd}`
      output = "#{version}\n#{'-'*version.length}\n#{changes}\n"

      unless pretend?
        File.open('CHANGELOG.md', 'r+') do |file|
          current = file.readlines
          current.insert(3, output)
          file.pos = 0;
          file.puts current
        end
      else
        puts output.split("\n").map!{|s| "    #{s}"}.join("\n")
      end
    end

    task :update_references => :chdir do
      puts "Updating version references to #{version}"

      cmd = "sed -i '' \"s/@version .*/@version #{version}/\" frameworks/runtime/core.js"
      pretend? ? puts(cmd) : system(cmd)

      cmd = "sed -i '' \"s/SC.VERSION = .*/SC.VERSION = '#{version}';/\" frameworks/runtime/core.js"
      pretend? ? puts(cmd) : system(cmd)
    end

    task :commit => :chdir do
      puts "Commiting Version Bump"
      unless pretend?
        system "git reset"
        system "git add CHANGELOG.md frameworks/runtime/core.js"
        system "git commit -m 'Version bump - #{version}'"
      end
    end

    task :tag => :chdir do
      puts "Tagging REL-#{version}"
      system "git tag REL-#{version}" unless pretend?
    end

    task :push => :chdir do
      puts "Pushing Repo"
      unless pretend?
        print "Are you sure you want to push the framework repo to github? (y/N) "
        res = STDIN.gets.chomp
        if res == 'y'
          system "git push"
          system "git push --tags"
        else
          puts "Not Pushing"
        end
      end
    end

    task :prepare => [:update, :changelog, :update_references]
    task :deploy => [:commit, :tag, :push]

  end

  namespace :abbot do

    task :chdir do
      chdir File.dirname(__FILE__)
    end

    task :update do
      puts "Checking updating repo"
      system "git pull" unless pretend?
    end

    task :changelog => :chdir do
      last_tag = `git describe --tags --abbrev=0`.strip
      puts "Getting Changes since #{last_tag}"

      cmd = "git log #{last_tag}..HEAD --format='* %s'"
      puts cmd

      changes = `#{cmd}`
      output = "*SproutCore #{version} (#{Time.now.strftime("%B %d, %Y")})*\n\n#{changes}\n"

      unless pretend?
        File.open('CHANGELOG', 'r+') do |file|
          current = file.read
          file.pos = 0;
          file.puts output
          file.puts current
        end
      else
        puts output.split("\n").map!{|s| "    #{s}"}.join("\n")
      end
    end

    task :commit => :chdir do
      puts "Commiting Version Bump"
      unless pretend?
        system "git reset"
        system "git add CHANGELOG VERSION.yml lib/frameworks/sproutcore"
        system "git commit -m 'Version bump - #{version}'"
      end
    end

    task :tag => :chdir do
      puts "Tagging REL-#{version}"
      system "git tag REL-#{version}" unless pretend?
    end

    task :push => :chdir do
      puts "Pushing Repo"
      unless pretend?
        print "Are you sure you want to push the abbot repo to github? (y/N) "
        res = STDIN.gets.chomp
        if res == 'y'
          system "git push"
          system "git push --tags"
        else
          puts "Not Pushing"
        end
      end
    end

    task :prepare => [:update, :changelog]
    task :deploy => [:commit, :tag, :push]

  end

  namespace :gems do

    task :build do
      versions = [rvm_mri, rvm_jruby].compact
      unless versions.empty?
        puts "Building for #{versions.join(", ")}"
        system "rvm #{versions.join(',')} exec gem build sproutcore.gemspec" unless pretend?
      else
        puts "Building for current version"
        system "gem build sproutcore.gemspec" unless pretend?
      end
    end

    task :push do
      Dir["sproutcore-#{version}*.gem"].each do |g|
        puts "Pushing #{g}"
        unless pretend?
          print "Are you sure you want to push the gem to RubyGems.org? (y/N) "
          res = STDIN.gets.chomp
          if res == 'y'
            system "gem push #{g}"
          else
            puts "Not Pushing"
          end
        end
      end
    end

    task :prepare => []
    task :deploy => [:build, :push]

  end

  task :prepare => ["framework:prepare", "abbot:prepare", "gems:prepare"]
  task :deploy => ["framework:deploy", "abbot:deploy", "gems:deploy"]

end
