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
  - Update CHANGELOG
  - Make sure the framework is up to date
  - Add a new tag
  - Build and push the gem:
      gem build sproutcore.gemspec
      gem push sproutcore-VERSION.gem
  - Switch to JRuby and repeat:
      gem build sproutcore.gemspec
      gem push sproutcore-VERSION-java.gem
END

end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
  puts "RSpec is not installed. Please install if you want to run tests."
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
  puts "`gem install packager` for packaging tasks"
end
