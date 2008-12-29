module Abbot
  
  module Builder

    class Base
      
      def initialize(opts={})
      end
      
      def build!(entry, build_path)
      end
    end
    
    # Built-in Builder simply copies the source path to the build path.
    class CopyFiles < Base
      def build!(entry, build_path)
        File.cp_r(entry.source_path, build_path)
      end
    end

  end
  
end

Abbot.require_all_libs_relative_to(__FILE__)
