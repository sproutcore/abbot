require "chance/instance"
require "chance/factory"

require 'sass'

# If available, use oily_png, which is faster
begin
  require "oily_png"
rescue Exception
  require "chunky_png"
end

module Chance
  
  CONFIG = {
    :verbose => false
  }

  @_current_instance = nil

  @files = {}
  
  @clear_files_immediately = false
  
  class << self
    attr_accessor :files, :_current_instance, :clear_files_immediately

    def add_file(path, content=nil)
      mtime = 0
      if content.nil?
        mtime = File.mtime(path).to_f
      end
      
      if @files[path]
        return update_file_if_needed(path, content)
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

    # if the path is a valid filesystem path and the mtime has changed, this invalidates
    # the file. Returns the mtime if the file was updated.
    def update_file_if_needed(path, content=nil)
      if @files[path]
        mtime = File.mtime(path).to_f
        if mtime > @files[path][:mtime]
          update_file(path, content)
        end
        
        return mtime
      else
        return false
      end
    end

    def remove_file(path)
      if not @files.has_key? path
        puts "Could not remove " + path + " because it is not in system."
        return
      end

      @files.delete(path)

      puts "Removed " + path if Chance::CONFIG[:verbose]
    end
    
    # Removes all files from Chance; used to reset environment for testing.
    def remove_all_files
      @files = {}
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
      _preprocess_rmagick_image(file) if file[:path] =~ /gif$|jpg$/

      file[:preprocessed] = true
    end

    def _preprocess_png(file)
      puts "LOAD FILE #{file[:path]}"
      file[:canvas] = ChunkyPNG::Canvas.from_blob(file[:content])
    end

    def _preprocess_rmagick_image(file)
      file[:canvas] = nil
      begin
        require "rmagick"
      rescue LoadError
        file[:error] = "RMagick is require to process gifs and jpgs. (gem install rmagick)"
        return
      end

      begin
        file[:canvas] = Magick::Image.from_blob(file[:content])[0]
      rescue Exception => e
        file[:error] = e
      end
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

