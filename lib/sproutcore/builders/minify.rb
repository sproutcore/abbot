require 'fileutils'

module SC

  # This builder combines several javascript files into a single file.  It is
  # used to prepare a single javascript file for production use.  This build
  # tool expects the javascript files to have already been processed for any
  # build directives such sc_static().
  #
  class Builder::Minify < Builder
    
    # main entry called by build tasls
    def self.build(entry, dst_path, kind)
      new(entry, kind).build(dst_path)
    end
    
    def initialize(entry=nil, kind=nil)
      super(entry)
      @kind = kind
    end
    
    # override this method in subclasses to actually do build
    def build(dst_path)
      send("build_#{@kind}".to_sym, dst_path)
    end
    
    def build_css(dst_path)
      lines = readlines(entry.source_path)
      options = {
        :preserveComments => false,
        :preserveNewlines => false,
        :preserveSpaces => true,
        :preserveColors => false,
        :skipMisc => false
      }
      output = SC::Helper::CSSPacker.new.compress(lines.join, options)
      writelines dst_path, [output]
    end
    
    # Minify some javascript by invoking the YUI compressor.
    def build_javascript(dst_path)
      yui_root = File.expand_path(File.join(LIBPATH, '..', 'vendor', 'yui-compressor'))
      jar_path = File.join(yui_root, 'yuicompressor-2.4.2.jar')
      filecompress = "java -jar " + jar_path + " --charset utf-8 " + entry.source_path + " -o " + dst_path
      SC.logger.info  'Compressing with YUI .... '+ dst_path
      SC.logger.debug `#{filecompress}`
      
      if $?.exitstatus != 0
        SC.logger.fatal("!!!!YUI compressor failed, please check that your js code is valid and doesn't contain reserved statements like debugger;")
        SC.logger.fatal("!!!!Failed compressing ... "+ dst_path)
      end
      
    end
    
  end
  
end
