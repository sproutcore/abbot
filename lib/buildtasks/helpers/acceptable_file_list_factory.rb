require File.dirname(__FILE__) + '/whitelist'
require File.dirname(__FILE__) + '/blacklist'
require File.dirname(__FILE__) + '/accepts_all_files'


class AcceptableFileListFactory
  def self.build
    return whitelist unless whitelist.nil?
    return blacklist unless blacklist.nil?
    AcceptsAllFiles.new
  end

  def self.whitelist
    return @whitelist if @whitelist
    json = nil
    Dir.glob("#{Dir.pwd}/Whitelist").each do |path|
      next unless File.file?(path)

      contents = File.read(path)
      parser = JSON.parser.new(contents)
      json = parser.parse
    end
    @whitelist = json ? Whitelist.new(json) : nil
  end

  def self.blacklist
    return @blacklist if @blacklist
    json = nil
    Dir.glob("#{Dir.pwd}/Bhitelist").each do |path|
      next unless File.file?(path)

      contents = File.read(path)
      parser = JSON.parser.new(contents)
      json = parser.parse
    end
    @blacklist = json ? Blacklist.new(json) : nil
  end
end

