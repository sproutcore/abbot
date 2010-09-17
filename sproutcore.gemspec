$:.push File.expand_path("../lib", __FILE__)
require "sproutcore/version"

Gem::Specification.new do |s|
  s.name = 'sproutcore'
  s.version = SproutCore::VERSION
  s.authors = 'Sprout Systems, Inc.  Apple Inc. and contributors'
  s.email = 'contact@sproutcore.com'
  s.homepage = 'http://www.sproutcore.com'
  s.summary = "SproutCore is a platform for building native look-and-feel applications on  the web"

  s.add_dependency 'rack', '>= 0.9.1'
  s.add_dependency 'json_pure', ">= 1.1.0"
  s.add_dependency 'extlib', ">= 0.9.9"
  s.add_dependency 'erubis', ">= 2.6.2"
  s.add_dependency 'thor', '>= 0.14'
  s.add_dependency 'thin', '~> 1.2.7'

  s.add_development_dependency 'gemcutter', ">= 0.1.0"
  s.add_development_dependency 'rspec', ">= 1.2.0"
  s.add_development_dependency 'rake'

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

