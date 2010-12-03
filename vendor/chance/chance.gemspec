# -*- encoding: utf-8 -*-
require File.expand_path("../lib/chance/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "chance"
  s.version     = Chance::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = []
  s.email       = []
  s.homepage    = "http://rubygems.org/gems/chance"
  s.summary     = "Builds SproutCore themes."
  s.description = "Builds SproutCore themes, with spriting, data-urls, SCSS, and more."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "chance"

  s.add_dependency "thor", "~>0.14.2"
  s.add_dependency "fssm", "~>0.1.4"
  s.add_dependency "haml", "~>3.0.21"
  s.add_dependency "compass", "~>0.10.5"
  s.add_dependency 'oily_png', '~> 0.2.0'
  
  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files bin`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
