require "chance/instance"

begin
  require "oily_png"
rescue Exception
  require "chunky_png"
end

module Chance
  supports_importers = false
  begin
    require 'chance/importer'
    supports_importers = true
  rescue Exception
    require 'sass'
  end
  
  CONFIG = {
    :verbose => false
  }
  
  SUPPORTS_IMPORTERS = supports_importers

  @_current_instance = nil

  @files = {}
  
  class << self
    attr_accessor :files, :_current_instance

    def add_file(path, content=nil)
      mtime = 0
      if content.nil?
        mtime = File.mtime(path).to_f
      end
      
      if @files[path]
        mtime = File.mtime(path).to_f
        update_file(path, content) if mtime > @files[path][:mtime]
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
        mtime = File.mtime(path).to_f
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
        # note: CSS files should be opened as UTF-8.
        f = File.open(path, path =~ /css$/ ? 'r:UTF-8' : 'rb')
        file[:content] = f.read
        f.close
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

