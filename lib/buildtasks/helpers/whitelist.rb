require File.dirname(__FILE__) + '/whitelist/whitelist_rules'

class Whitelist
  def initialize(json)
    @rules = WhitelistRules.new

    json.each do |file_location, file_specifications|
      file_specifications = [file_specifications] if file_specifications.kind_of?(String)
      file_specifications.each {|specification| @rules.add_rule(file_location, specification)}
    end
  end

  def include?(file_path)
    @rules.count {|rule| rule.matches?(file_path)} != 0
  end
end
