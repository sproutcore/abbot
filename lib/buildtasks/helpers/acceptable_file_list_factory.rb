require File.dirname(__FILE__) + '/whitelist'

class AcceptsAllFiles
  def include?(file_path)
    true
  end
end

class AcceptableFileListFactory
  def self.build
    return whitelist unless whitelist.nil?
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
end

