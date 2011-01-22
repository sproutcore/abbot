# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/html"

module SC

  # Builds an HTML files.  This will setup an HtmlContext and then invokes
  # the render engines for each source before finally rendering the layout.
  class Builder::Test < Builder::Html

    def initialize(entry)
      super(entry)
      @layout = @target.config[:test_layout] || 'lib/test.rhtml'
    end

    # Always include any required test targets as well when loading unit
    # tests.
    def expand_required_targets(target, opts = {})
      opts[:test] = true
      super(target, opts)
    end

    protected

    def render_entry(entry)
      entry.stage!

      case entry[:ext]
      when 'js'
        render_jstest(entry)
      when 'rhtml'
        entry.target.buildfile.invoke 'render:erubis',
          :entry    => entry,
          :src_path => entry[:staging_path],
          :context  => self
      end
    end

    def default_content_for_key; :body; end

    # Renders an individual test into a script tag.  Also places the test
    # into its own closure so that globals defined by one test will not
    # conflict with any others.
    def render_jstest(entry)
      lines = readlines(entry[:staging_path])
      pathname = entry[:staging_path].gsub(/^.+\/staging\//,'').gsub(/"/, '\"')
      lines.unshift %[<script type="text/javascript">\nif (typeof SC !== "undefined") {\n  SC.mode = "TEST_MODE";\n  SC.filename = "#{pathname}"; \n}\n(function() {\n]
      lines.push    %[\n})();\n</script>\n]
      @content_for_final = (@content_for_final || '') + lines.join("")
    end

  end

end
