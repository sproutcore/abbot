# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
# ===========================================================================

require 'rubygems'
require 'logger'
require 'extlib'
require 'yaml'

$:.delete_if {|f| f =~ /json_pure-/ } if $:.any? {|f| f =~ /json-/ }

if RUBY_VERSION <= '1.8'
  $KCODE = 'u'
  require 'jcode'
  class String ; def valid_encoding? ; true ; end ; end
end

require "sproutcore/version"

module SproutCore

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Global variable that can store specific environmental settings.  This is
  # where you will find the build mode among other things set by sc-build.
  #
  def self.env
    @env ||= HashStruct.new(
      :build_mode => :debug,
      :buildfile_names => %w(Buildfile sc-config sc-config.rb),
      :whitelist_name => "Whitelist",
      :blacklist_name => "Blacklist"
    )
  end
  def self.env=(hash); @env = HashStruct.new(hash); end

  # Returns a standard logger object.  You can replace this with your own
  # logger to redirect all SproutCore log output if needed.  Otherwise, a
  # logger will bre created based on your env.log_level and env.logfile
  # options.
  def self.logger
    return @logger unless @logger.nil?

    if env[:logfile]
      @logger = Logger.new env[:logfile], 10, 1024000
    else
      @logger = Logger.new $stderr

      # if we are logging to the screen, no reason to use a std loggin fmt
      @logger.formatter = lambda do |severity, time, progname, msg|
        [severity, time.strftime("%H:%M:%S.") + "%.3d" % (time.usec / 100000), '~', msg.to_s, "\n"].join(' ')
      end
    end

    @logger.level = (env[:log_level] == :debug) ? Logger::DEBUG : ((env[:log_level] == :info) ? Logger::INFO : Logger::WARN)

    return @logger
  end
  attr_writer :logger

  # Returns the current build mode. The build mode is determined based on the
  # current environment build_mode settings.  Note that for backwards
  # compatibility reasons, :development and :debug are treated as being
  # identical.
  def self.build_mode
    ret = env[:build_mode] || :production
    ret = ret.to_sym unless ret.nil?
    ret = :debug if ret == :development # backwards compatibility
    ret
  end

  def self.build_mode=(new_mode)
    new_mode = new_mode.to_sym
    new_mode = :debug if new_mode == :development
    env[:build_mode] = new_mode
    self.build_mode
  end

  # Returns a project instance representing the builtin library
  def self.builtin_project
    @builtin_project ||= SC::Project.new(PATH)
  end

  # Returns the current project, if defined.  This is normally only set
  # when you start sc-server in interactive mode.
  def self.project; @project; end
  def self.project=(project); @project = project; end

  # Attempts to load a project for the current working directory or from the
  # passed directory location.  Returns nil if no project could be detected.
  # This is just a shorthand for creating a Project object.  It is useful
  # when using the build tools as a Ruby library
  def self.load_project(path = nil, opts = {})
    path = File.expand_path(path.nil? ? Dir.pwd : path)
    if FalseClass === opts[:discover]
      SC::Project.load path, :parent => SC.builtin_project
    else # attempt to autodiscover unless disabled
      SC::Project.load_nearest_project path, :parent => SC.builtin_project
    end
  end

  # Additional targets to be included in the project. Each item is a hash
  # with :path and :name attributes
  def self.include_targets
    @include_targets ||= []
  end

  # Adds a target to be included in the project SproutCore builds.
  #
  # This is useful to make additional frameworks available to SproutCore apps.
  def self.include_target(target_name, target_path)
    include_targets << { :name => target_name, :path => target_path }
  end

  def self.html_jar
    @html_jar ||= begin
      yui_root = File.expand_path("../../vendor/sproutcore", __FILE__)
      File.join(yui_root, 'SCCompiler.jar')
    end
  end
  
  def self.js_jar
    @js_jar ||= begin
      yui_root = File.expand_path("../../vendor/sproutcore", __FILE__)
      File.join(yui_root, 'lib/yuicompressor-2.4.8.jar')
    end
  end

  def self.profile(env)
    if ENV[env]
      require "ruby-prof"
      RubyProf.start
      yield
      result = RubyProf.stop
      printer = RubyProf::CallStackPrinter.new(result)
      printer.print(File.open("output.html", "w"), :min_percent => 0)
      exit!
    else
      yield
    end
  end

  def self.attach_prefix(url)
    $script_name ? "#{$script_name}#{url}" : url
  end
end  # module SC

SC = SproutCore # alias

Encoding.default_external = "UTF-8" if defined?(Encoding)

require "sproutcore/buildfile"
require "sproutcore/tools"
require "sproutcore/rack"
require "sproutcore/helpers"
require "sproutcore/deprecated/view_helper"
require "sproutcore/builders"
require "sproutcore/models"
require "sproutcore/render_engines/erubis"
require "sproutcore/render_engines/haml"

# EOF
