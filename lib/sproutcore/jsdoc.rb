# This utility module will use jsdoc to create documentation from a SproutCore
# client.  Note that for this to work you must have Java installed (sudder).
module SproutCore

  module JSDoc

    # Creates the documentation for the specified set of clients, replacing
    # the contents of the output file.  Requires some of the following
    # options.
    #
    # :bundle => A Bundle instance - or -
    # :files  => Absolute paths to input files
    # :build_path => absolute path to the build root.  Uses the bundle if not provided.
    def self.generate(opts = {})
      bundle = opts[:bundle]
      build_path = opts[:build_path] || File.join(bundle.build_root, '-docs', 'data')
      raise "MISSING OPTION: :bundle => bundle or :build_path => path required for JSDoc" if build_path.nil?

      # get the list of files to build for.
      files = opts[:files]
      if files.nil?
        raise "MISSING OPTION: :bundle => bundle or :files => list of files required for JSDoc" if bundle.nil?
        entries = bundle.sorted_javascript_entries(:hidden => :include)
        files = entries.map { |x| x.composite? ? nil : x.source_path }.compact.uniq
      end

      # Ensure directory exists
      FileUtils.mkdir_p(build_path)

      # Now run jsdoc
      jsdoc_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'jsdoc'))
      jar_path = File.join(jsdoc_root, 'app', 'js.jar')
      runjs_path = File.join(jsdoc_root, 'app', 'run.js')
      template_path = File.join(jsdoc_root, 'templates', 'sproutcore')

      puts %(GENERATING: java -Djsdoc.dir="#{jsdoc_root}" -jar "#{jar_path}" "#{runjs_path}" -t="#{template_path}" -d="#{build_path}" "#{ files * '" "' }" -v)

      # wrap files in quotes...

      SC.logger.debug `java -Djsdoc.dir="#{jsdoc_root}" -jar "#{jar_path}" "#{runjs_path}" -t="#{template_path}" -d="#{build_path}" "#{ files * '" "' }" -v`

    end
  end
end
