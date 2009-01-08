require 'rubygems'
gem 'rake', '> 0.8.0'

module Abbot

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
    @env ||= HashStruct.new(:build_mode => :debug, :buildfile_names => %w(Buildfile))
  end
  def self.env=(hash); @env = HashStruct.new(hash); end
  
  def self.build_mode
    ret = env.build_mode || :debug
    ret = ret.to_sym unless ret.nil?
    ret = :debug if ret == :development # backwards compatibility
    ret
  end
  
end  # module Abbot

Abbot.require_all_libs_relative_to(__FILE__)

# Makes code more readable
YES = true
NO = false

# EOF
