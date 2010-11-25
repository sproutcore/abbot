$:.push File.expand_path("../lib", __FILE__)
require "sproutcore/version"

is_jruby = Gem::Platform.local.os == "java"

Gem::Specification.new do |s|
  s.name = 'sproutcore'
  s.version = SproutCore::VERSION
  s.authors = 'Strobe, Inc., Sprout Systems, Inc.  Apple Inc. and contributors'
  s.email = 'contact@sproutcore.com'
  s.homepage = 'http://www.sproutcore.com'
  s.summary = "SproutCore is a platform for building native look-and-feel applications on the web"

  s.platform = 'java' if is_jruby

  s.add_dependency 'rack', '~> 1.2.1'
  s.add_dependency 'json_pure', "~> 1.4.6"
  s.add_dependency 'extlib', "~> 0.9.15"
  s.add_dependency 'erubis', "~> 2.6.6"
  s.add_dependency 'thor', '~> 0.14.3'
  s.add_dependency 'haml', '~> 3.0.22'
  s.add_dependency 'compass', '~> 0.10.5'
  s.add_dependency 'chunky_png', '~> 0.10.4'

  if is_jruby
    s.add_dependency 'mongrel', '~> 1.1.5'
  else
    s.add_dependency 'thin', '~> 1.2.7'
    s.add_dependency 'eventmachine', '>= 0.12.10' # Thin requires wrong version
  end

  s.add_development_dependency 'gemcutter', "~> 0.6.0"
  s.add_development_dependency 'rspec', "~> 1.3.0"
  s.add_development_dependency 'rake'

  # Optional features, used in tests
  s.add_development_dependency 'haml', "~> 3.0.18"
  s.add_development_dependency 'less', "~> 1.2.21"
  s.add_development_dependency 'RedCloth', "~> 4.2.3"
  s.add_development_dependency 'BlueCloth', "~> 1.0.1"
  
  s.require_paths << 'lib'
  s.require_paths << 'vendor/chance/lib'

  s.rubyforge_project = "sproutcore"
  s.extra_rdoc_files  = %w[History.txt README.txt]

  s.files        = `git ls-files`.split("\n")
  s.files       += Dir[".htaccess", "lib/frameworks/sproutcore/**/*"]
  s.files       -= Dir[".gitignore", ".gitmodules", ".DS_Store", ".hashinfo", ".svn", ".git"]
  s.files.reject!  { |file| file =~ %r{^(coverage|tmp)/} }

  s.executables  = `git ls-files`.split("\n").map { |f| f[%r{^bin/(.*)}, 1] }.compact
  s.description  = "SproutCore is a platform for building native look-and-feel applications on " \
                   "the web.  This Ruby library includes a copy of the SproutCore JavaScript " \
                   "framework as well as a Ruby-based build system called Abbot."
end

