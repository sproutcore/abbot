require 'fileutils'
require 'tempfile'

require "sproutcore"
Dir["#{File.dirname(__FILE__)}/../lib/buildtasks/helpers/*.rb"].each {|f| require f}

module SC

  # A Temporary project will clone the project_root before instantiating.
  # You can call cleanup when you are finished to remove the cloned project.
  # This way you can make changes to the project - perform builds, etc,
  # and easily reset for another test.
  class TemporaryTestProject < Project

    attr_reader :real_project_root

    def initialize(proot, opts ={})

      @tempfile = Tempfile.new(File.basename(proot)) # keep placeholder
      @real_project_root = proot
      proot = "#{@tempfile.path}-project"
      FileUtils.cp_r(@real_project_root, proot) # clone real_world
      super(proot, opts)
    end

    def cleanup
      # delete the project root.  Double check this is stored in a tmp loc
      # just to avoid problems.
      if project_root =~ /^#{Regexp.escape Dir.tmpdir}/
        FileUtils.rm_r(project_root)
      else
        puts "WARNING: Not deleting project_root: #{project_root}"
      end
    end

  end

  module SpecHelpers

    # env doesn't automatically reset
    def save_env
      @env ||= []
      @env << { :env => SC.env.dup, :build_mode => SC.build_mode }
    end

    def restore_env
      e = (@env || []).pop
      SC.env = e[:env]
      SC.build_mode = e[:build_mode]
    end

    def fixture_path(*path_items)
      (path_items = path_items.flatten).unshift 'fixtures'
      path = path_items.map { |pi| pi.to_s }.join("/")
      File.expand_path("../#{path}", __FILE__)
    end

    def empty_project
      SC::Project.new fixture_path('buildfiles', 'empty_project')
    end

    # The builtin project (i.e. default Buildfile)
    def builtin_project
      SC::Project.new fixture_path('..','..','lib')
    end

    # Loads a project from fixtures, including the builtin project as
    # parent
    def fixture_project(*paths)
      SC::Project.new fixture_path(*paths), :parent => builtin_project
    end

    #####################################################
    # BUILD TESTING
    #

    def temp_project(*paths)
      SC::TemporaryTestProject.new fixture_path(*paths), :parent => builtin_project
    end

    def files_eql(path_a, path_b)
      return false if File.exist?(path_a) != File.exist?(path_b)
      if File.exist?(path_a)
        file_a = File.read(path_a)
        file_b = File.read(path_b)
        return file_a == file_b
      end
      return true # neither paths exist
    end

    # Writes a dummy file at the specified path.
    def write_dummy(at_path, string = "DUMMY")
      FileUtils.mkdir_p(File.dirname(at_path))
      f = File.open(at_path, 'w')
      f.write(string)
      f.close
      return string
    end

    # Tests to see if the file at_path matches the dummy file or not.
    def is_dummy(at_path, string = "DUMMY")
      return false if !File.exist?(at_path)
      File.read(at_path) == string
    end

    # Make the a newer than b.  touch then sleep until it works...
    def make_newer(path_a, path_b)
      FileUtils.touch(path_a)
      while File.mtime(path_a) <= File.mtime(path_b)
        sleep(0.1)
        FileUtils.touch(path_a)
      end
    end

    #####################################################
    # TOOL TESTING
    #

    # Captures a stdout/stdin/stderr stream for evaluation
    def capture(stream)
      SC.instance_variable_set('@logger', nil) # reset
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure
        eval("$#{stream} = #{stream.upcase}")
      end
      SC.instance_variable_set('@logger', nil) # reset again..
      result
    end

    alias silence capture

  end
end

# EOF
