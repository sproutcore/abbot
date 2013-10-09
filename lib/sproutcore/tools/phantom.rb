# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2013 Strobe Inc.
#            and contributors
# ===========================================================================

module SC

  class Tools

    stop_on_unknown_option! :phantom

    desc "phantom ARGS", "Runs the PhantomJS unit test runner, passing arguments straight through"

    def phantom(*args)
      result = false
      target = find_targets('/sproutcore').first

      if target
        test_runner_path = File.expand_path(File.join('phantomjs', 'test_runner.js'), target.source_root)
        if File.file? test_runner_path
          result = system "phantomjs #{test_runner_path} #{args.join(' ')}"
        else
          SC.logger.fatal "Could not find PhantomJS test runner"
        end
      else
        SC.logger.fatal "Could not find /sproutcore target"
      end

      exit(1) unless result
    end

  end
end

