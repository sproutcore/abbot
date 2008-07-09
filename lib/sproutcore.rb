$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'activesupport'

module SproutCore

  # Returns a library for the current working directory.  This is useful when
  # working on the command line
  def self.library
    Library.library_for(Dir.pwd)
  end

  def self.library_for(path, opts={})
    Library.library_for(path, opts)
  end

  def self.logger; @logger ||= Logger.new(STDOUT); end
  def self.logger=(new_logger); @logger = new_logger; end

end

# Force load the code files.  Others may be loaded only as required
%w(library bundle bundle_manifest bundle_installer jsdoc jsmin version).each do |fname|
  require "sproutcore/#{fname}"
end

SC= SproutCore
