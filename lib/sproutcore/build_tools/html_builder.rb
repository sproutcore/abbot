require 'sproutcore/helpers'
require 'sproutcore/view_helpers'

module SproutCore

  module BuildTools

    # Whenever you build an HTML file for a SproutCore client, an instance of
    # this class is created to actually process and build the HTML using
    # Erubus or Haml.  If you want to add more methods to use in your HTML files, just
    # include them in HtmlContext.
    #
    class HtmlContext

      include SproutCore::Helpers::TagHelper
      include SproutCore::Helpers::TextHelper
      include SproutCore::Helpers::CaptureHelper
      include SproutCore::Helpers::StaticHelper
      include SproutCore::Helpers::DomIdHelper
      include SproutCore::ViewHelpers

      attr_reader :entry, :bundle, :entries, :filename, :language, :library, :renderer, :unit_test, :platform

      def initialize(entry, bundle, deep=true)
        @entry = nil
        @language = entry.language
        @platform = entry.platform
        @bundle = bundle
        @library = bundle.library

        # Find all of the entries that need to be included.  If deep is true,
        # the include required bundles.  Example composite entries to include
        # their members.
        if deep
          @entries = bundle.all_required_bundles.map do |cur_bundle|
            ret = (cur_bundle == bundle) ? [entry] : cur_bundle.entries_for(:html, :language => language, :hidden => :include)
            ret.map do |e|
              e.composite? ? e.composite : [e]
            end
          end
          @entries = @entries.flatten.compact.uniq
        else
          @entries = entry.composite? ? entry.composite : [entry]
        end

        # Clean out any composites we might have collected.  They have already
        # been expanded.  Also clean out any non-localized rhtml files.
        @entries.reject! { |entry| entry.composite? || (entry.type == :html && !entry.localized?) }

        # Load any helpers before we continue
        bundle.all_required_bundles.each do |cur_bundle|
          require_helpers(nil, cur_bundle)
        end

      end

      # Actually builds the HTML file from the entry (actually from any
      # composite entries)
      def build
        @layout_path = bundle.layout_path

        # Render each filename. By default, the output goes to the :resources
        # content section
        entries.each do |entry|
          content_for :resources do
            _build_one(entry)
          end
        end

        # Finally, render the layout.  This should produce the final output to
        # return
        _render(@layout_path)
      end

      # Returns the current bundle name.  Often useful for generating titles,
      # etc.
      def bundle_name; bundle.bundle_name; end

      private

        # Builds a single entry
        def _build_one(entry)
          # avoid double render of layout path
          return if entry.source_path == @layout_path

          @entry = entry
          @filename = @entry.filename
          begin
            _render(@entry.source_path)
          ensure
            @filename = nil
            @entry = nil
          end
        end

        def _render(file_path)
          SC.logger.debug("~ Rendering #{file_path}")
          
          # if this is a JS file, read the JS into a unit_test variable then
          # output a special unit_test.rhtml file.
          if file_path =~ /\.js$/
            @unit_test = File.read(file_path)
            
            unit_test_template = File.join(File.dirname(__FILE__), 'test_template.rhtml')
            input = File.read(unit_test_template)
            
          # Otherwise, just read in the source file
          else
            input = File.read(file_path)
          end
          
          @renderer = case file_path
            
          # rhtml & .html.erb get processed through Erubis. 
          # JS files passed in for unit tests are also erubis.
          when /\.js$/, /\.rhtml$/, /\.html.erb$/
            Sproutcore::Renderers::Erubis.new(self)
            
          # haml is processed through HAML
          when /\.haml$/
            Sproutcore::Renderers::Haml.new(self)
          
          end
          _render_compiled_template( @renderer.compile(input) )
        end

        # Renders a compiled template within this context
        def _render_compiled_template(compiled_template)
          self.instance_eval "def __render(); #{compiled_template}; end"
          begin
            self.send(:__render) do |*names|
              self.instance_variable_get("@content_for_#{names.first}")
            end
          ensure
            class << self; self end.class_eval{ remove_method(:__render) } rescue nil
          end
        end

    end

    # Builds an html file for the specified entry.  If deep is true, then this
    # will also find all of the html entries for any required bundles and
    # include them in the built html file.
    def self.build_html(entry, bundle, deep=true)
      context = HtmlContext.new(entry, bundle, deep)
      output = context.build

      FileUtils.mkdir_p(File.dirname(entry.build_path))
      f = File.open(entry.build_path, 'w')
      f.write(output)
      f.close

    end

    # Building a test is almost like building a single page except that we
    # do not include all the other html templates.  Also, if the test is a
    # JS file instead, we need to generate the HTML template.
    def self.build_test(entry, bundle)
      build_html(entry, bundle, false)
    end

  end
end
