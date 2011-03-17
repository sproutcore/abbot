module SC::Helpers

  # Helper to minify JavaScript files. You can either call the class method
  # minify, or use << to add to the queue. If you add to the queue, you have
  # no knowledge of when the minification will finish.
  class Minifier
    # CLASS HELPERS
    def self.<<(path)
      SC::Helpers::Minifier.instance << path
    end

    def self.minify(path)
      SC::Helpers::Minifier.instance.minify path
    end

    def self.wait
      SC::Helpers::Minifier.instance.wait
    end

    # Returns the instance (Minifier is a singleton)
    @@instance = nil
    def self.instance
      @@instance = SC::Helpers::Minifier.new if @@instance.nil?

      @@instance
    end


    # MINIFICATION MANAGER
    def initialize
      @queue = []
      @working_minifiers = []
      @max_minifiers = 4

      @safety = Mutex.new
    end

    def wait
      @working_minifiers.each {|m| m.join }
    end


    def <<(item)
      @queue << item

      _process_queue
    end

    # If the queue is not empty, and there are any available workers,
    # spawn min(queue.length, max_minifiers) minifiers. They'll handle
    # the queue on their own.
    def _process_queue
      [@queue.length, @max_minifiers - @working_minifiers.length].min.times {
        _spawn_minifier
      }
    end

    def _spawn_minifier
      thread = Thread.new {
        @working_minifiers << Thread.current

        while @queue.length > 0
          queue = @safety.synchronize {
            queue = @queue.clone
            @queue.clear

            queue
          }

          next if queue.length == 0

          minify(queue)

          # NOTE: MORE ITEMS COULD BE ADDED TO QUEUE BY NOW,
          # SO WE LOOP.
        end

        @working_minifiers.delete Thread.current
      }
    end

    def minify(paths)
      # Convert to string if an array
      if paths.respond_to? :join
        paths = paths * "\" \""
      end

      yui_root = File.expand_path("../../../../vendor/sproutcore", __FILE__)
      jar_path = File.join(yui_root, "SCCompiler.jar")

      if SC.env[:yui_minification]
        command = "java -Xmx256m -jar \"" + jar_path + "\" -yuionly \"" + paths + "\" 2>&1"
      else
        command = "java -Xmx256m -jar \"" + jar_path + "\" \"" + paths + "\" 2>&1"
      end

      output = `#{command}`

      SC.logger.info output
      if $?.exitstatus != 0
        SC.logger.fatal(output)
        SC.logger.fatal("!!!! Minifying failed. Please check that your JS code is valid.")
        SC.logger.fatal("!!!! Failed compiling #{paths}")

        exit(1)
      end
    end

  end
end
