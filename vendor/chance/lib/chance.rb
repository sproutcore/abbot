require "chance/instance"
require "chunky_png"

module Chance
  CONFIG = {
    :verbose => false
  }

  @_current_instance = nil

  @files = {}
  
  class << self
    attr_accessor :files, :_current_instance

    def add_file(path, content=nil)
      mtime = 0
      if content.nil?
        mtime = File.new(path).mtime
      end
      
      if @files[path]
        mtime = File.new(path).mtime
        update_file(path) if mtime > @files[path][:mtime]
        return
      end
      
      file = {
        :mtime => mtime,
        :path => path,
        :content => content,
        :preprocessed => false
      }

      @files[path] = file
      #puts "Added " + path if Chance::CONFIG[:verbose]
    end

    def update_file(path, content=nil)
      if not @files.has_key? path
        puts "Could not update " + path + " because it is not in system."
        return
      end
      
      mtime = 0
      if content.nil?
        mtime = File.new(path).mtime
      end

      file = {
        :mtime => mtime,
        :path => path,
        :content => content,
        :preprocessed => false
      }

      @files[path] = file
      puts "Updated " + path if Chance::CONFIG[:verbose]
    end

    def remove_file(path)
      if not @files.has_key? path
        puts "Could not remove " + path + " because it is not in system."
        return
      end

      @files.delete(path)

      puts "Removed " + path if Chance::CONFIG[:verbose]
    end
    
    def remove_all_files
      #@files = {}
    end
    
    def has_file(path)
      return false if not @files.has_key? path
      return true
    end
    
    def get_file(path)
      if not @files.has_key? path
        puts "Could not find " + path + " in Chance."
        return nil
      end
      
      file = @files[path]
      
      if file[:content].nil?
        f = File.open(path, "rb")
        file[:content] = f.read
      end
      
      if not file[:preprocessed]
        _preprocess file
      end
      
      return file
    end

  private
    def _preprocess(file)
      _preprocess_css(file) if file[:path] =~ /css$/
      _preprocess_png(file) if file[:path] =~ /png$/
      
      file[:preprocessed] = true
    end

    def _preprocess_png(file)
      file[:content] = ChunkyPNG::Canvas.from_blob(file[:content])
    end

    def _preprocess_css(file)
      content = file[:content]

      requires = []
      content = content.gsub(/sc_require\(['"]?(.*?)['"]?\);?/) {|match|
        requires.push $1
        ""
      }

      file[:requires] = requires
      file[:content] = content
    end
    
  end
end

