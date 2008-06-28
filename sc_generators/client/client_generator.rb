require 'sproutcore/generator_helper'

class ClientGenerator < RubiGen::Base

  include SproutCore::GeneratorHelper

  default_options :author => nil

  attr_reader :name

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    extract_options
    assign_names!(@name)
  end

  def manifest
    record do |m|
      m.directory 'clients'
      apply_template(m,"clients/#{@name}")
      m.readme '../README'
    end
  end

  protected
    def banner
      <<-EOS
Creates a ...

USAGE: #{$0} #{spec.name} name
EOS
    end

    def add_options!(opts)
      opts.on('-l', "--library=LIBRARY_ROOT", String, "Specify an alternate library root other than current working directory", "Default: working directory") { |options[:library_root] | }
    end

    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      @destination_root = File.expand_path(options[:library_root]) unless options[:library_root].nil?
    end

end
