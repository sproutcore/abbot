require "sass"

module Chance

  # Chance creates an in-memory file that @imports all other files. As these
  # other files are preprocessed _and_ not in a place that Sass knows how to
  # find, Chance has to have its own importer.
  class Importer < Sass::Importers::Base
  
    def initialize(imager)
      @imager = imager
    end
  
    # SCSS's cache tries to serialize this; we can't allow that.
    def marshal_dump
      return ""
    end
  
    def marshal_load(data)
    
    end

    def find_relative(name, base, options)
      find(name, options)
    end
  
    def find(name, options)
      if name == "chance_images"
        css = @imager.css
        name = "_chance_images.scss"
      else
        css = Chance.get_file(name[0..-6])
      
        if css.nil?
          return nil
        end
      
        css = css[:parsed_css]
      end
    
      Sass::Engine.new(css, options.merge({
        :syntax => :scss,
        :importer => self,
        :filename => name
      }))
    end
  
    def mtime(name, options)
      Chance.get_file(name[0..-6])[:mtime]
    end
  
    def key(name, options)
      [self.class.name + ":" + name, File.basename(name)]
    end
  
    def to_s
      "Chance Importer"
    end
  end

end