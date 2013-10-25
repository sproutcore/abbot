$:.push File.expand_path("../lib", __FILE__)
require "sproutcore/version"

os = Gem::Platform.local.os
is_jruby = (os == "java")

Gem::Specification.new do |s|
  s.name = 'sproutcore'
  s.version = SproutCore::VERSION
  s.authors = 'Strobe, Inc., Apple Inc. and contributors'
  s.email = 'community@sproutcore.com'
  s.license = 'MIT'
  s.homepage = 'http://www.sproutcore.com'
  s.summary = "SproutCore is a platform for building native look-and-feel applications on the web"

  s.platform = 'java'        if is_jruby

  s.add_dependency 'rack', '~> 1.2'
  s.add_dependency 'json_pure', "~> 1.4"
  s.add_dependency 'extlib', "~> 0.9"
  s.add_dependency 'erubis', "~> 2.6"
  s.add_dependency 'thor', '~> 0.18'
  s.add_dependency 'sass', '~> 3.1'
  s.add_dependency 'haml', '~> 3.1'

  s.add_dependency 'compass', '~> 0.11'
  s.add_dependency 'chunky_png', '~> 1.2'

  # We need to add two eventmachine dependencies so that `thin` (eventmachine >= 0.12.6) and `em-http-request` (eventmachine ~> 1.0.0.beta.4) don't cause bundler to throw a dependency exception.
  s.add_dependency 'eventmachine', '>= 0.12.6'
  s.add_dependency 'eventmachine', '~> 1.0'

  s.add_dependency 'em-http-request', '~> 1.0'

  if is_jruby
    s.add_dependency 'mongrel', '~> 1.1'
  else
    s.add_dependency 'thin', '~> 1.2'
  end

  s.add_development_dependency 'gemcutter', "~> 0.6"
  s.add_development_dependency 'rspec', "~> 2.5"
  s.add_development_dependency 'rake'

  # Optional features, used in tests
  s.add_development_dependency 'less', "~> 1.2"
  s.add_development_dependency 'RedCloth', "~> 4.2"
  s.add_development_dependency 'BlueCloth', "~> 1.0"

  s.require_paths << 'lib'
  s.require_paths << 'vendor/chance/lib'


  s.rubyforge_project = "sproutcore"
  s.extra_rdoc_files  = %w[History.rdoc README.rdoc]

  s.files        = `git ls-files`.split("\n")
  s.files       += Dir[".htaccess", "lib/frameworks/sproutcore/**/*"]
  s.files       -= Dir[".gitignore", ".gitmodules", ".DS_Store", ".hashinfo", ".svn", ".git"]
  s.files.reject!  { |file| file =~ %r{^(coverage|tmp)/} || file =~ /\.(psd|drawit|graffle)/ }

  s.executables  = `git ls-files`.split("\n").map { |f| f[%r{^bin/(.*)}, 1] }.compact
  s.description  = "SproutCore is a platform for building native look-and-feel applications on " \
                   "the web.  This Ruby library includes a copy of the SproutCore JavaScript " \
                   "framework as well as a Ruby-based build system called Abbot."
end

