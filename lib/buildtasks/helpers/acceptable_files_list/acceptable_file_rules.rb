require File.dirname(__FILE__) + '/acceptable_file_rule'

class AcceptableFileRules

  def initialize
    @rules = []
  end

  def add_rule(file_location, specification)
    @rules << AcceptableFileRule.new(file_location, specification)
  end

  def matches_file?(file_path)
    @rules.each do |rule|
      return true if rule.matches?(file_path)
    end
    false
  end

  def count(&block)
    @rules.count(&block)
  end
end