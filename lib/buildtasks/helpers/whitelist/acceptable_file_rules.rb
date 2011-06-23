require File.dirname(__FILE__) + '/whitelist_rule'

class AcceptableFileRules
  ALWAYS_ACCEPTED_FILE_TYPES= [
    '.manifest',
    '.htm',
    '.html',
    '.rhtml',
    '.png',
    '.jpg',
    '.jpeg',
    '.gif'
  ]
  def initialize
    @rules = []
    ALWAYS_ACCEPTED_FILE_TYPES.each { |file_type| self.add_rule('.*', file_type)}
  end

  def add_rule(file_location, specification)
    @rules << WhilelistRule.new(file_location, specification)
  end

  def count(&block)
    @rules.count &block
  end
end