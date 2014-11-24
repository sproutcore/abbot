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
      if not paths.kind_of?(Array)
        paths = [paths]
      end

      # Split paths into HTML and JS
      html_paths = paths.select {|p| p =~ /\.html$/}
      js_paths = paths.select {|p| p =~ /\.js$/}

      if html_paths.length > 0
        command = %{java -jar "#{SC.html_jar}" "#{html_paths.join '" "'}" 2>&1}
        output = `#{command}`

        SC.logger.info output
        if $?.exitstatus != 0
          SC.logger.fatal(output)
          SC.logger.fatal("!!!! Minifying failed. Please check that your JS code is valid.")
          SC.logger.fatal("!!!! Failed compiling #{paths}")

          exit(1)
        end
      end

      if js_paths.length > 0
        js_paths.each {|p|
          p = Pathname.new(p).relative_path_from(Pathname.new(Dir.getwd))
          command = %{java -Xmx512m -XX:MaxPermSize=256m -jar "#{SC.js_jar}" -o "#{p}" "#{p}" 2>&1}
          output = `#{command}`

          SC.logger.info output
          if $?.exitstatus != 0
            SC.logger.fatal(output)
            SC.logger.fatal("!!!! Minifying failed. Please check that your JS code is valid.")
            SC.logger.fatal("!!!! Failed compiling #{paths}")

            exit(1)
          end
        }
      end

      # SCyui doesn't need a -o. It writes to the original path.



    end

  end
end
