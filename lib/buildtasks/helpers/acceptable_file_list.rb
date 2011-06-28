require File.dirname(__FILE__) + '/acceptable_files_list/acceptable_file_rules'

class AcceptableFileList
  def initialize(json)
    @rules = AcceptableFileRules.new

    json.each do |file_location, file_specifications|
      file_specifications = [file_specifications] if file_specifications.kind_of?(String)
      file_specifications.each {|specification| @rules.add_rule(file_location, specification)}
    end
  end

  def acceptable_file?(file_path)
    raise 'You must implement acceptable_file?'
  end
end