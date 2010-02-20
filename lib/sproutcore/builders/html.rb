# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require File.expand_path(File.join(File.dirname(__FILE__), 'base'))

module SC

  # Builds an HTML files.  This will setup an HtmlContext and then invokes
  # the render engines for each source before finally rendering the layout.
  class Builder::Html < Builder::Base
    
    include SC::Helpers::TagHelper
    include SC::Helpers::TextHelper
    include SC::Helpers::CaptureHelper
    include SC::Helpers::StaticHelper
    include SC::Helpers::DomIdHelper
    include SC::ViewHelpers
    
    # the entry we are building
    attr_reader :entry
    
    # bundle is an alias for target included for backwards compatibility
    attr_reader :target, :bundle
    
    # the full set of entries we plan to build
    attr_reader :entries
    
    # the final filename
    attr_reader :filename
    
    # the current builder language
    attr_reader :language
    
    # library is an alias for project for backwards compatibility
    attr_reader :project, :library
    
    # the current render
    attr_reader :renderer
    
    # manifest owning the current entry
    attr_reader :manifest
    
    def target_name; target.target_name.to_s.sub(/^\//,''); end
    alias_method :bundle_name, :target_name # backwards compat
    
    def config; target.config; end
    
    # The entry for the layout we want to build.  this will be used to 
    # stage the layout if needed..
    def layout_entry
      @manifest.entry_for(@layout) || @manifest.entry_for(@layout, :hidden => true)
    end
    
    # the path to the current layout for the resource.  this is computed 
    # from the layout property, which is a relative pathname.
    def layout_path
      entry = layout_entry
      entry.nil? ? nil : entry.staging_path
    end
    
    def initialize(entry)
      super(entry)
      @target = @bundle = entry.manifest.target
      @filename = entry.filename
      @language = @entry.manifest.language
      @project = @library = @target.project
      @manifest = entry.manifest
      @renderer = nil
      
      # set the current layout from the target's config.layout
      @layout = @target.config.layout || 'lib/index.rhtml'
      
      # find all entries -- use source_Entries + required if needed
      @entries = entry.source_entries.dup
      if entry.include_required_targets?
        @target.expand_required_targets.each do |target|
          cur_manifest = target.manifest_for(@manifest.variation).build!
          cur_entry = cur_manifest.entry_for(entry.filename, :combined => true) || cur_manifest.entry_for(entry.filename, :hidden => true, :combined => true)
          next if cur_entry.nil?
          @entries += cur_entry.source_entries
        end
      end
    end

    # Returns the expanded list of required targets for the passed target.
    # This method can be overridden by subclasses to provide specific 
    # config settings.
    def expand_required_targets(target, opts = {})
      opts[:debug] = target.config.load_debug
      opts[:theme] = true
      return target.expand_required_targets(opts)
    end
    
    # Renders the html file, returning the resulting string which can be 
    # written to a file.
    def render
      
      # render each entry...
      @entries.each { |entry| render_entry(entry) }
      
      # then finally compile the layout.
      if self.layout_path.nil?
        raise "html_builder could not find a layout file for #{@layout}" 
      end
      
      compile(SC::RenderEngine::Erubis.new(self), self.layout_path, :_final_)
      return @content_for__final_
    end
      
    def build(dst_path)
      if CONFIG.html5_manifest
        $to_html5_manifest << dst_path
        $to_html5_manifest_networks = CONFIG.html5_manifest_networks
        @content_for_html5_manifest = true
      end
      writelines dst_path, [self.render]
    end
    
    def default_content_for_key; :resources; end
    
    # Loads the passed input file and then hands it to the render_engine 
    # instance to compile th file.  the results will be targeted at the
    # @content_for_resources area by default unless you pass an optional
    # content_for_key or otherwise override in your template.
    #
    # === Params
    #  render_engine:: A render engine instance
    #  input_path:: The file to load
    #  content_for_key:: optional target for content
    #
    # === Returns
    #  self
    #
    def compile(render_engine, input_path, content_for_key = nil)
      
      if content_for_key.nil?
        if @in_partial
          content_for_key = :_partial_ 
        else
          content_for_key = self.default_content_for_key 
        end
      end
      
      if !File.exist?(input_path)
        raise "html_builder could compile file at #{input_path} because the file could not be found" 
      end
      
      old_renderer = @renderer
      @renderer = render_engine  # save for capture...
      
      input = File.read(input_path)
      
      content_for content_for_key do
        _render_compiled_template( render_engine.compile(input) )
      end
      
      @render = old_renderer
      return self
    end

    private
    
    # Renders an entry as a partial.  This will insert the results inline
    # instead of into a content div.
    def render_partial(entry) 

      # save off
      old_partial = @content_for__partial_
      old_in_partial = @in_partial

      @content_for__partial_ = ''
      @in_partial = true
      render_entry(entry)
      ret = @content_for__partial_
      @content_for__partial_ = old_partial
      @in_partial = old_in_partial
      
      return ret
      
    end
    
    # Renders a single entry.  The entry will be staged and then its 
    # render task will be executed.
    def render_entry(entry)
      @content_for_designer = '<script type="text/javascript">SC.suppressMain = YES;</script>' if $design_mode
      entry.stage!
      entry.target.buildfile.invoke entry.render_task,
        :entry    => entry, 
        :src_path => entry.staging_path,
        :context  => self
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
  
end
