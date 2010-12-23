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
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new
rescue LoadError
  puts "RSpec is not installed. Please install if you want to run tests."
end
