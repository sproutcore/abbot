require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])
require 'tempfile'

# Add dummy task we can use to test general option processing
class SC::Tools
  desc "dummy", "a dummy task"
  def dummy; end
end

describe SC::Tools do
  
  include SC::SpecHelpers
  
  # executes once
  before(:all) do
    @tmpfile = Tempfile.new('foo')
    @tmpdir = File.join(File.dirname(@tmpfile.path), 'foo')
    # only really need the dir
    @tmpfile.close
  end
  
  # executes before each 'it'
  before(:each) do
    FileUtils.mkdir_p @tmpdir
    @options = { :target => @tmpdir, :'very-verbose' => true }
    @tool = SC::Tools.new({})
    @tool.options = @options
  end
  
  describe "gen command line options parser" do

    # it "project generator camel case" do
    #   @tool.gen('project', 'MyTestProject')
    #   # instance variables
    #   @tool.namespace.should == ''
    #   @tool.class_name.should == 'MyTestProject'
    #   @tool.namespace_with_class_name.should == 'MyTestProject'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 0
    #   @tool.file_path.should == 'my_test_project'
    #   
    #   @tool.files_generated.should == 1
    # end
    # 
    # it "project generator lower case" do
    #   @tool.gen('project', 'my_test_project')
    #   # instance variables
    #   @tool.namespace.should == ''
    #   @tool.class_name.should == 'MyTestProject'
    #   @tool.namespace_with_class_name.should == 'MyTestProject'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 0
    #   @tool.file_path.should == 'my_test_project'
    #   
    #   @tool.files_generated.should == 1
    # end
    # 
    # it "app generator camel case" do
    #   @tool.gen('app', 'MyTestApp')
    #   # instance variables
    #   @tool.namespace.should == ''
    #   @tool.class_name.should == 'MyTestApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 0
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 5
    # end
    # 
    # it "app generator lower case" do
    #   @tool.gen('app', 'my_test_app')
    #   # instance variables
    #   @tool.namespace.should == ''
    #   @tool.class_name.should == 'MyTestApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 0
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 5
    # end
    # 
    # it "model generator camel case" do
    #   @tool.gen('model', 'MyTestApp.App')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'App'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.App'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 3
    # end
    # 
    # it "model generator lower case" do
    #   @tool.gen('model', 'my_test_app/app')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'App'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.App'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 3
    # end
    # 
    # it "view generator camel case" do
    #   @tool.gen('view', 'MyTestApp.MyAppView')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'MyApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyAppView'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 2
    # end
    # 
    # it "view generator lower case" do
    #   @tool.gen('view', 'my_test_app/my_app_view')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'MyApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyAppView'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 2
    # end
    # 
    # it "controller generator camel case" do
    #   @tool.gen('controller', 'MyTestApp.MyAppController')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'MyApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyAppController'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 2
    # end
    # 
    # it "controller generator lower case" do
    #   @tool.gen('controller', 'my_test_app/my_app_controller')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'MyApp'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyAppController'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 2
    # end
    # 
    # it "test generator camel case" do
    #   @tool.gen('test', 'MyTestApp.MyTest')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp'
    #   @tool.class_name.should == 'MyTest'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyTest'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 1
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 1
    # end
    # 
    # it "test generator camel case with method" do
    #   @tool.gen('test', 'MyTestApp.MyTest.MyMethod')
    #   # instance variables
    #   @tool.namespace.should == 'MyTestApp.MyTest'
    #   @tool.class_name.should == 'MyTest'
    #   @tool.namespace_with_class_name.should == 'MyTestApp.MyTest.MyTest'
    #   @tool.method_name.should == 'myMethod'
    #   @tool.class_nesting_depth.should == 2
    #   @tool.file_path.should == 'my_test_app'
    #   
    #   @tool.files_generated.should == 1
    # end
    # 
    # it "language generator camel case" do
    #   @tool.gen('language', 'English')
    #   # instance variables
    #   @tool.namespace.should == ''
    #   @tool.class_name.should == 'English'
    #   @tool.namespace_with_class_name.should == 'English'
    #   @tool.method_name.should == nil
    #   @tool.class_nesting_depth.should == 0
    #   @tool.file_path.should == 'english.lproj'
    #   
    #   @tool.files_generated.should == 1
    # end
    
  end
  
  # executes after each example is run
  after(:each) do
    FileUtils.remove_dir @tmpdir
  end
  
end
