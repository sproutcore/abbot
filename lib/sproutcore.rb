require 'rubygems'
require 'logger'
require 'extlib'

#gem 'rake', '> 0.8.0'

$KCODE = 'u'
require 'jcode'

# Makes code more readable
YES = true
NO = false

module SproutCore

  # :stopdoc:
  VERSION = '1.0.0'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

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

  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end
  
  # Global variable that can store specific environmental settings.  This is
  # where you will find the build mode among other things set by sc-build.
  #
  def self.env
    @env ||= HashStruct.new(:build_mode => :debug, :buildfile_names => %w(Buildfile sc-config sc-config.rb))
  end
  def self.env=(hash); @env = HashStruct.new(hash); end
  
  # Returns a standard logger object.  You can replace this with your own
  # logger to redirect all SproutCore log output if needed.  Otherwise, a
  # logger will bre created based on your env.log_level and env.logfile 
  # options.
  def self.logger 
    return @logger unless @logger.nil?
    
    if env.logfile
      @logger = Logger.new env.logfile, 10, 1024000
    else
      @logger = Logger.new STDERR
      
      # if we are logging to the screen, no reason to use a std loggin fmt
      @logger.formatter = lambda do |severity, time, progname, msg|
        [severity, '~', msg.to_s, "\n"].join(' ') 
      end
    end
    
    @logger.level = (env.log_level == :debug) ? Logger::DEBUG : ((env.log_level == :info) ? Logger::INFO : Logger::WARN)
    
    return @logger
  end
  attr_writer :logger

  # Returns the current build mode. The build mode is determined based on the
  # current environment build_mode settings.  Note that for backwards 
  # compatibility reasons, :development and :debug are treated as being 
  # identical.
  def self.build_mode
    ret = env.build_mode || :debug
    ret = ret.to_sym unless ret.nil?
    ret = :debug if ret == :development # backwards compatibility
    ret
  end
  
  def self.build_mode=(new_mode)
    new_mode = new_mode.to_sym
    new_mode = :debug if new_mode == :development
    env.build_mode = new_mode
    self.build_mode
  end
  
  # Returns a project instance representing the builtin library
  def self.builtin_project
    @builtin_project ||= SC::Project.new(PATH)
  end
  
end  # module SC

SC = SproutCore # alias

SC.require_all_libs_relative_to(__FILE__)
%w(buildfile models helpers deprecated builders render_engines tools rack).each do |dir|
  SC.require_all_libs_relative_to(__FILE__, ['sproutcore', dir])
end

# EOF
