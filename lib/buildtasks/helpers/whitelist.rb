require File.dirname(__FILE__) + '/acceptable_file_list'

class Whitelist < AcceptableFileList
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

  def initialize(json)
    super
    ALWAYS_ACCEPTED_FILE_TYPES.each { |file_type| @rules.add_rule('.*', file_type)}
  end

  def acceptable_file?(file_path)
    @rules.matches_file?(file_path)
  end
end
