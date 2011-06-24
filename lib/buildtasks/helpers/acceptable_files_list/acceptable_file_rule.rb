class AcceptableFileRule
  def initialize(file_location, file_specification)
    @file_location, @file_specification = file_location, file_specification
  end

  def matches?(file_path)
    Regexp.new("#{@file_location}.?#{@file_specification}").match(file_path)
  end
end