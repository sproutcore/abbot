require "fileutils"

module Chance
  class Test
    attr_accessor :name

    def initialize(name, directory)
      @directory = directory
      @name = name

      @input = File.join(directory, "input")
      @output = File.join(directory, "output")

      @chance = Chance::Instance.new
    end

    # Maps files into Chance
    def setup
      Dir.glob(File.join(@input, "**/*")).each {|file|
        next if File.directory? file

        rel = file[@input.length+1..-1]

        Chance.add_file(file)
        @chance.map_file(rel, file)
      }
    end

    def clean
      Chance.remove_all_files
    end

    def run
      setup

      failures = output_files.count {|file| not check_output_for(file) }

      clean

      return failures
    end

    def output_files
      Dir.glob(File.join(@output, "**/*")).map {|file|
        next if File.directory? file

        file[@output.length + 1..-1]
      }
    end

    def output_for(file)
      if file.end_with? ".parsed.css"
        input_file = file[0..-1-".parsed.css".length] + ".css"

        # Create a parser; skip Chance instance.
        parser = Chance::Parser.new(@chance.get_file(input_file)[:content], { :slices => {} })
        parser.parse

        return parser.css

      else
        # assume standard Chance file
        return @chance.output_for(file)
      end

    end

    def check_output_for(file)
      expected = File.new(File.join(@output, file)).read
      return check(output_for(file), expected, file)
    end

    def check(result, expected, name)
      if result == expected
        if Chance::CONFIG[:verbose]
          puts "OK: " + name
        end

        true
      else
        if Chance::CONFIG[:verbose]
          puts "NOT OK: " + name
          puts "GOT:"
          puts result
          puts "EXPECTED:"
          puts expected
        end

        false
      end
    end

    # Used to overwrite current results due to behavior change
    def approve
      setup

      output_files.each {|file|
        if not check_output_for(file)
          puts "Updating file: #{file}"
          File.new(File.join(@output, file), "w").write(output_for(file)) 
        end
      }

      clean
    end

  end
end
