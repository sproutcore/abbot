require File.dirname(__FILE__) + '/acceptable_file_list'

class Blacklist < AcceptableFileList
  def acceptable_file?(file_path)
    not(@rules.matches_file?(file_path))
  end
end
