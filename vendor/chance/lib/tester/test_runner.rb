require "tester/test"
module Chance
  class TestRunner
    def initialize(dir)
      @directory = dir
    end

    def all_tests
      # All folders containing "input" and "output" folders are tests.
      dirs = Dir.glob(File.join(@directory, "**/*")).select {|dir|
        next false if not File.directory?(dir)

        entries = Dir.entries(dir)
        next false if not entries.include?("input")
        next false if not entries.include?("output")

        true
      }

      dirs.map {|dir| test_for(dir[@directory.length + 1..-1]) }
    end

    def test_for(dir)
      Test.new(dir, File.join(@directory, dir))
    end
  end
end
