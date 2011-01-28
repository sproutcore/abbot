module SC::Helpers

  # Helper to minify JavaScript files. You can either call the class method
  # minify!, or add paths using <<, then call minify_queue! to minify all files
  # at once (which improves performance significantly.)

  class Minifier
    @@queue = []

    def self.<<(item)
      @@queue << item
    end

    def self.queue
      @@queue
    end

    # Minifies a path or an array of paths
    def self.minify!(paths)
        yui_root = File.expand_path("../../../../vendor/sproutcore", __FILE__)
        jar_path = File.join(yui_root, 'SCCompiler.jar')

        # Convert to string if an array
        if paths.respond_to? :join
          paths = paths * "\" \""
        end

        if SC.env[:yui_minification]
          command = "java -Xmx256m -jar \"" + jar_path + "\" -yuionly \"" + paths + "\" 2>&1"
        else
          command = "java -Xmx256m -jar \"" + jar_path + "\" \"" + paths + "\" 2>&1"
        end

        SC.logger.info  'Minifying...'
        SC.logger.info  command

        output = `#{command}`     # It'd be nice to just read STDERR, but
                                  # I can't find a reasonable, commonly-
                                  # installed, works-on-all-OSes solution.
        SC.logger.info output
        if $?.exitstatus != 0
          SC.logger.fatal(output)
          SC.logger.fatal("!!!! Minifying failed, please check that your js code is valid")
          SC.logger.fatal("!!!! Failed compiling ... " + paths)
          exit(1)
        end
    end

    # Minimizes the files in the queue, then empties the queue
    def self.minify_queue!
      SC::Helpers::Minifier.minify! @@queue
      @@queue = []
    end

  end
end
