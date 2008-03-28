require 'sproutcore/generator_helper'

class ViewGenerator < RubiGen::Base
  
  include SproutCore::GeneratorHelper
  
  default_options :author => nil
  
  attr_reader :name, :client_location
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    extract_options
    assign_names!(@name)
  end

  def manifest
    record do |m|
      fp = client_file_path('views','js','view')
      build_client_directories(m, fp)
      m.template 'view.js', fp
      
      fp = client_file_path('tests/views', 'rhtml')
      build_client_directories(m, fp)
      m.template 'test.rhtml', fp
    end
  end

  protected
    def banner
      <<-EOS
Creates a SproutCore model objects

USAGE: #{$0} #{spec.name} client_name/model_name [ClassName]
EOS
    end

    def add_options!(opts)
      opts.on("-l", '--loc="Location"', String, "Location of build. If not passed, search clients and frameworks dirs", "Default: none") { |options[:loc]| }
    end
    
    def extract_options
      @client_location = options[:loc]
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end
end