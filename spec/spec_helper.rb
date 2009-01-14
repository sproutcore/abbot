require 'fileutils'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib sproutcore]))

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

module SC
  
  # A Temporary project will clone the project_root before instantiating.
  # You can call cleanup when you are finished to remove the cloned project.
  # This way you can make changes to the project - perform builds, etc, 
  # and easily reset for another test.
  class TemporaryTestProject < Project
    
    attr_reader :real_project_root
    
    def initialize(proot, opts ={})
      
      @tempfile = Tempfile.new('compute_build_number') # keep placeholder
      @real_project_root = proot
      proot = "#{@tempfile.path}-project"
      FileUtils.cp_r(@real_project_root, proot) # clone real_world
      super(proot, opts)
    end
      
    def cleanup
      # delete the project root.  Double check this is stored in a tmp loc
      # just to avoid problems.
      FileUtils.rm_r(project_root) if project_root =~ /^#{Regexp.escape Dir.tmpdir}/
    end
    
  end
  
  module SpecHelpers
    
    def fixture_path(*path_items)
      (path_items = path_items.flatten).unshift 'fixtures'
      path_items.map! { |pi| pi.to_s }
      File.expand_path File.join(File.dirname(__FILE__), path_items)
    end
    
    # Make the a newer than b.  touch then sleep until it works...
    def make_newer(path_a, path_b)
      FileUtils.touch(path_a)
      while File.mtime(path_a) <= File.mtime(path_b)
        sleep(0.1)
        FileUtils.touch(path_a)
      end
    end

    def empty_project
      SC::Project.new fixture_path('buildfiles', 'empty_project')
    end
    
    # The builtin project (i.e. default Buildfile)
    def builtin_project
      SC::Project.new fixture_path('..','..')
    end
    
    # Loads a project from fixtures, including the builtin project as 
    # parent
    def fixture_project(*paths)
      SC::Project.new fixture_path(*paths), :parent => builtin_project
    end

    def temp_project(*paths)
      SC::TemporaryTestProject.new fixture_path(*paths), :parent => builtin_project
    end
    
    #####################################################
    # TOOL TESTING
    #
    
    # Captures a stdout/stdin/stderr stream for evaluation
    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure 
        eval("$#{stream} = #{stream.upcase}")
      end

      result
    end

    alias silence capture
    
  end
end

# EOF
