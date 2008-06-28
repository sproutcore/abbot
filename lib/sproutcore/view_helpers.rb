
module SproutCore

  # The PageHelper is a singleton object that can render the Page javascript
  # object.
  module PageHelper

    @@render_contexts = []
    @@outlets = {}
    @@outlet_names = []
    @@styles = []
    @@defines = {}

    # This is the current helper state used when rendering the HTML.  When
    # a view helper is rendered, it may add itself as an outlet to the current
    # helper state instead of to the page helper.
    def self.current_render_context
      @@render_contexts.last
    end

    def self.push_render_context(state)
      @@render_contexts.push(state)
    end

    def self.pop_render_context
      @@render_contexts.pop
    end

    # reset the page helper.
    def self.reset!
      @@render_contexts = []
      @@outlets = {}
      @@outlet_names = []
      @@styles = []
      @@defines = {}
    end

    def self.set_define(key, opts = {})
      @@defines[key] = opts
    end

    def self.set_outlet(key,opts = {})
      @@outlet_names << key
      @@outlets[key] = opts
    end

    def self.add_styles(styles)
      @@styles << styles
    end

    # renders the page object for the current page.  If you include a prefix
    # that will be used to create a separate page object.  Otherwise, the
    # object will live in the SC namespace.
    #
    # returns the text to insert into the HTML.
    def self.render_js(prefix = 'SC')

      outlets = []
      @@outlet_names.each do | key |
        opts = @@outlets[key]
        outlet_path = opts[:outlet_path] || "##{opts[:id] || key}"
        outlets << %{  #{key}: #{opts[:class] || 'SC.View'}.extend({\n  #{ opts[:properties].gsub("\n","\n  ") }\n  }).outletFor("#{outlet_path}") }
      end

      # defines let you define classes to include in your UI.
      ret = @@defines.map do | key, opts |
        %{#{key} = #{opts[:class] || 'SC.View'}.extend({\n  #{ opts[:properties] }\n});}
      end
      ret << %{#{prefix}.page = SC.Page.create({\n#{ outlets * ",\n\n" }\n}); }
      return ret * "\n"

    end

    def self.render_css
      if @@styles.size > 0
        %(<style type="application/css">\n#{ @@styles * "\n" }\n</style>)
      else
        ''
      end
    end

  end

  module ViewHelperSupport

    @@helpers = {}
    def self.find_helper(helper_name)
      @@helpers[helper_name.to_sym] || @@helpers[:view]
    end

    def self.set_helper(helper_name,obj)
      @@helpers[helper_name.to_sym] = obj
    end

    class RenderContext

      # options passed in from the view helper
      attr_reader :item_id
      attr_accessor :outlet
      attr_accessor :define
      attr_accessor :current_helper
      attr_accessor :client_builder
      attr_reader :render_source

      def initialize(item_id, opts={}, client_builder = nil, render_source=nil)
        @_options = opts.dup
        @bindings = (@_options[:bind] || {}).dup
        @outlets = {}
        @prototypes = {}
        @item_id = item_id
        @outlet = opts[:outlet]
        @define = opts[:define]
        @client_builder = client_builder
        @outlet_names = []
        @render_source = render_source

        @attributes = (@_options[:attributes] || {}).dup

        @_properties = {}
        if @_options[:properties]
          @_options[:properties].each do | key, value |
            @_properties[key.to_s.camelize(:lower)] = prepare_for_javascript(value)
          end
        end
      end

      def options
        @_options
      end

      def set_outlet(key,opts = {})
        @outlet_names << key
        @outlets[key] = opts
      end

      def prepare_bindings
        @bindings.each do | k,v |
          key = k.to_s.camelize(:lower) + 'Binding'
          @_properties[key] = v.include?('(') ? v : prepare_for_javascript(v)
        end
      end

      def prepare_outlets
        return if @outlets.size == 0
        outlets = []
        @outlet_names.each do | key |
          opts = @outlets[key]
          outlet_key = key.to_s.camelize(:lower)
          outlets << outlet_key unless opts[:lazy]

          outlet_path = opts[:outlet_path] || ".#{opts[:id] || key }?"
          str = %{#{opts[:class] || 'SC.View'}.extend({\n#{ opts[:properties] }\n}).outletFor("#{outlet_path}")}
          @_properties[outlet_key] = str
        end

        @_properties['outlets'] = outlets
      end

      def parent_helper(opts = {})
        if @current_helper && @current_helper.parent_helper
          @_options.merge! opts
          @current_helper.parent_helper.prepare_context(self)
        end
      end

      ### RENDER METHODS
      def render_content
        @attributes[:id] = @item_id if @item_id && !(@outlet || @define)

        old_client_builder = self.client_builder
        self.client_builder = @content_render_client_builder unless @content_render_client_builder.nil?
        ret = _do_render(@content_render)
        self.client_builder = old_client_builder
        return ret
      end

      def render_view
        prepare_bindings
        prepare_outlets
        _do_render(@view_render)
      end

      def view_class
        @view_class
      end

      def render_styles
        _do_render(@styles_render)
      end

      ### BASIC CONFIG METHODS
      # These are called in the helper's prepare_context method.

      # This method must be called to configure the view.
      def view(view_class,text = nil, &block)
        @view_class = view_class
        @view_render = text || block if (text || block)
      end

      # this method must be called to configure the HTML.
      # also captures the client builder in use at the time it is called.
      def content(text = nil, &block)
        @content_render_client_builder = self.client_builder
        @content_render = text || block if (text || block)
      end

      # this method may be called to add CSS styles
      def styles(text = nil, &block)
        @styles_render = text || block if (text || block)
      end

      def static_url(resource_name, opts = {})
        opts[:language] ||= @language
        entry = @client_builder.find_resource_entry(resource_name, opts)
        entry.nil? ? '' : entry.url
      end

      def blank_url
        static_url('blank.gif')
      end

      ### HTML HELPER METHODS

      # This will extract the specified value and put it into an ivar you can
      # access later during rendering.  For example:
      #
      #  var :label, 'Default label'
      #
      # will now be accessible in your code via @label
      #
      # Parameters:
      # option_key: (req) the option to map.
      # default_value: (opt) if passed, this will be used as the default value
      # if the option is not passed in.
      #
      # :key => (opt) the name of the resulting ivar.  defaults to the option
      # key.
      #
      # :optional => (opt) if true, then the attribute will not be included if
      # it is not explicitly passed in the options. if no default value is
      # specified, then this will default to true, otherwise defaults to
      # false.
      #
      # :constant => (opt) if true, then any passed in options will be ignored
      # for this key and the default you specify will be used instead.
      # Defaults to false
      #
      # you may also pass a block that will be used to compute the value at
      # render time.  Expect a single parameter which is the initial value.
      #
      def var(option_key, default_value=:__UNDEFINED__, opts={}, &block)
        ret = _pair(option_key, default_value, opts, &block)
        return if ret[2] # ignore
        instance_variable_set("@#{ret[0]}".to_sym, ret[1])
        ret[1]
      end

      # returns the standard attributes for the HTML.  This will automatically
      # include the item id.  You can also declare added attributes using the
      # attribute param.
      def attributes
        final_class_names = css_class_names
        final_styles = css_styles

        ret = @attributes.map do |key,value|

          # if the css class or css style is declared, replace the current
          # set coming from the view_helper
          if key.to_sym == :class && value
            final_class_names = value
            nil
          elsif key.to_sym == :style && value
            final_styles = value
            nil
          else
            value ? %(#{key}="#{value}") : nil
          end
        end

        # add in class names
        final_class_names = [final_class_names].flatten
        final_class_names << @item_id
        final_class_names.compact!
        unless final_class_names.empty?
          ret << %(class="#{final_class_names.uniq * ' '}")
        end

        # add in styles
        unless final_styles.nil?
          final_styles = [final_styles].flatten
          final_styles.compact!
          ret << %(style="#{final_styles.uniq * ' '}") unless final_styles.empty?
        end

        ret.compact * ' '
      end

      # Your view helper can add text to by appended to the styles attribute
      # by adding to this array.
      def css_styles
        @css_styles ||= []
      end

      def css_styles=(new_ary)
        @css_styles = new_ary
      end

      # Your view helper can add css classes to be appended to the classes
      # attribute by adding to this array.
      def css_class_names
        @css_class_names ||= []
      end

      def css_class_names=(new_ary)
        @css_class_names = new_ary
      end

      # This does the standard open tag with the default tag and attributes. Usually
      # you can use this.
      def open_tag
        %{<#{@tag} #{attributes}>}
      end
      alias_method :ot, :open_tag

      def close_tag
        %{</#{@tag}>}
      end
      alias_method :ct, :close_tag

      # Call this method in your view helper definition to map an option to
      # an attribute.  This attribute can then be rendered with attributes.
      # This method takes the same options as var
      def attribute(option_key, default_value=:__UNDEFINED__, opts={}, &block)
        ret = _pair(option_key, default_value, opts, &block)
        return if ret[2] # ignore
        @attributes[ret[0]] = ret[1]
      end

      # returns all the JS properties specified by the property method.
      def properties
        keys = @_properties.keys
        ret = []

        # example element, if there is one
        if @define
          @_properties['emptyElement'] = %($sel("#resources? .#{@item_id}:1:1"))
          ret << _partial_properties(['emptyElement'])
        end

        # outlets first
        if keys.include?('outlets')
          outlets = @_properties['outlets']
          @_properties['outlets'] = '["' + (outlets * '","') + '"]'
          ret << _partial_properties(['outlets'])
          ret << _partial_properties(outlets,",\n\n")
          keys.reject! { |k| outlets.include?(k) || (k == 'outlets') }
        end

        bindings = keys.reject { |k| !k.match(/Binding$/) }
        if bindings.size > 0
          ret << _partial_properties(bindings)
          keys.reject! { |k| bindings.include?(k) }
        end

        if keys.size > 0
          ret << _partial_properties(keys)
        end

        ret = ret * ",\n\n"
        '  ' + ret.gsub("\n","\n  ")
      end

      def _partial_properties(keys,join = ",\n")
        ret = keys.map do |key|
          value = @_properties[key]
          next if value.nil?
          %(#{key}: #{value})
        end
        ret * join
      end

      # Call this method to make a binding available or to set a default
      # binding.  You can use this for properties you want to allow a
      # binding for but don't want to take as a fully property.
      def bind(option_key, default_value=:__UNDEFINED__, opts={})
        key, v, ignore  = _pair(option_key, default_value, opts, false)

        # always look for the option key in the bindings passed by the user.
        # if present, this should override whatever we set
        if found = @bindings[option_key.to_sym] || @bindings[option_key.to_s]
          v = found
          ignore = false
          @bindings.delete option_key.to_sym
          @bindings.delete option_key.to_s
        end

        # finally, set the binding value.
        unless ignore
          v = v.include?('(') ? v : prepare_for_javascript(v)
          @_properties["#{key.camelize(:lower)}Binding"] = v
        end

      end

      # Call this method in your view helper to specify a property you want
      # added to the javascript declaration.  This methos take the same
      # options as var.  Note that normally the type of value returned here
      # will be marshalled into the proper type for JavaScript.  If you
      # provide a block to compute the property, however, the value will be
      # inserted directly.
      def property(option_key, default_value=:__UNDEFINED__, opts={}, &block)
        ret = _pair(option_key, default_value, opts, &block)
        key = ret[0].camelize(:lower)

        unless ret[2] # ignore
          value = ret[1]
          value = prepare_for_javascript(value) unless block_given?
          @_properties[key] = value
        end

        # also look for a matching binding and set it needed.
        if v = @bindings[option_key.to_sym] || @bindings[option_key.to_s]
          v = v.include?('(') ? v : prepare_for_javascript(v)
          @_properties["#{key}Binding"] = v
          @bindings.delete option_key.to_sym
          @bindings.delete option_key.to_s
        end

      end

      def prepare_for_javascript(value)
        return 'null' if value.nil?
        case value
        when String:
          %("#{ value.gsub('"','\"').gsub("\n",'\n') }")
        when Symbol:
          %("#{ value.to_s.gsub('"','\"').gsub("\n",'\n') }")
        when Array:
          "[#{value.map { |v| prepare_for_javascript(v) } * ','}]"
        when Hash:
          items = value.map do |k,v|
            [prepare_for_javascript(k),prepare_for_javascript(v)] * ': '
          end
          "{ #{items * ', '} }"
        when FalseClass:
          "false"
        when TrueClass:
          "true"
        else
          value.to_s
        end
      end

      ### INTERNAL SUPPORT
      private

      def _do_render(render_item)
        if render_item.nil?
          ''
        elsif render_item.instance_of?(Proc)
          render_item.call
        else
          render_item
        end
      end

      def _pair(option_key, default_value, opts, look_for_key = true)
        if default_value.instance_of?(Hash)
          opts = default_value
          default_value = :__UNDEFINED__
        end

        # get the attribute value. possibly return if no value and optional.
        optional = opts.has_key?(:optional) ? opts[:optional] : (default_value == :__UNDEFINED__)
        if opts[:constant] == true
          value = default_value
        elsif look_for_key && options.has_key?(option_key.to_sym)
          value = options[option_key.to_sym]
        elsif look_for_key && options.has_key?(option_key.to_s)
          value = options[option_key.to_s]
        else
          value = default_value
        end


        if (optional==true) && value == :__UNDEFINED__
          ignore = true
          value = nil
        else
          ignore = false
          value = nil if value == :__UNDEFINED__
          value = yield(value) if block_given?
        end

        attr_key = (opts[:key] || option_key).to_s
        [attr_key, value, ignore]
      end

    end

    class HelperState
      attr_reader :name
      attr_reader :parent_helper
      attr_reader :prepare_block

      def initialize(helper_name, opts={}, &block)
        @name = helper_name
        @prepare_block = block
        @parent_helper = SproutCore::ViewHelperSupport.find_helper(opts[:wraps] || opts[:extends] || :view)
        @extends = opts[:wraps].nil?
      end

      def prepare_context(render_context)
        # automatically call parent helper if extends was used.
        if parent_helper && @extends
          parent_helper.prepare_context(render_context)
        else
          render_context.current_helper = self
        end

        render_context.instance_eval &prepare_block
        render_context.current_helper = nil
      end

    end

    @@tick = 0
    def self._gen_id(type="id")
      @@tick += 1
      return "#{type}_#{(Time.now.to_i + @@tick)}"
    end

    extend SproutCore::Helpers::CaptureHelper
    extend SproutCore::Helpers::TextHelper

    # :outlet => define if you want this to be used as an outlet.
    # :prototype => define if you want this to be used as a prototype.
    def self.render_view(view_helper_id, item_id, opts={}, client_builder=nil, render_source=nil, &block)

      # item_id is optional.  If it is not a symbol or string, then generate
      # an item_id
      if item_id.instance_of?(Hash)
        opts = item_id; item_id = nil
      end
      item_id = _gen_id if item_id.nil?

      # create the new render context and set it.
      client_builder = opts[:client] if opts[:client]
      rc = RenderContext.new(item_id, opts, client_builder, render_source)
      hs = find_helper(view_helper_id)

      # render the inner_html using the block, if one is given.
      SproutCore::PageHelper.push_render_context(rc)
      rc.options[:inner_html] = capture(&block) if block_given?

      # now, use the helper state to prepare the render context.  This will
      # extract the properties from the options and setup the render procs.
      hs.prepare_context(rc) unless hs.nil?

      # how have the render context render the HTML content.  This may also
      # make changes to the other items to render.
      ret = rc.render_content

      SproutCore::PageHelper.pop_render_context

      # get the JS.  Save as an outlet or in the page.
      cur_rc = SproutCore::PageHelper.current_render_context
      view_class = opts[:view] || rc.view_class
      unless view_class.nil?
        view_settings = { :id => item_id, :class => view_class, :properties => rc.render_view, :lazy => opts[:lazy], :outlet_path => opts[:outlet_path] }

        # if an outlet item is passed, then register this as an outlet.
        outlet = opts[:outlet] || rc.outlet
        define = opts[:define]
        if outlet && cur_rc
          outlet = item_id if outlet == true
          cur_rc.set_outlet(outlet, view_settings)

        elsif define
          define = define.to_s.camelize.gsub('::','.')
          SproutCore::PageHelper.set_define(define, view_settings)

        # otherwise, add it to the page-wide setting.
        else
          prop = item_id.to_s.camelize(:lower)
          SproutCore::PageHelper.set_outlet(prop, view_settings)
        end
      end

      # get the styles, if any
      styles = rc.render_styles
      SproutCore::PageHelper.add_styles(styles) if styles && styles.size > 0

      # done. return the generated HTML
      concat(ret,block) if block_given?
      return ret
    end

  end

  module ViewHelpers

    def view_helper(helper_name,opts={},&prepare_block)
      hs = SproutCore::ViewHelperSupport::HelperState.new(helper_name,opts,&prepare_block)
      SproutCore::ViewHelperSupport.set_helper(helper_name, hs)

      ## install the helper method
      eval %{
        def #{helper_name}(item_id=nil, opts={}, &block)
          SproutCore::ViewHelperSupport.render_view(:#{helper_name}, item_id, opts, bundle, self, &block)
        end }

    end

    def render_page_views
      ret = %(<script type="text/javascript">\n#{SproutCore::PageHelper.render_js}\n</script>)
      SproutCore::PageHelper.reset!
      return ret
    end

    # Call this method to load a helper.  This will get the file contents
    # and eval it.
    def require_helpers(helper_name, bundle=nil)

      # save bundle for future use
      unless bundle.nil?
        old_helper_bundle = @helper_bundle
        @helper_bundle = bundle
      end

      # Get all the helper paths we want to load
      if helper_name.nil?
        paths = @helper_bundle.helper_paths
      else
        paths = [@helper_bundle.helper_for(helper_name)]
      end
      paths.compact!

      # Create list of loaded helper paths
      @loaded_helpers = [] if @loaded_helpers.nil?

      # If a helper path was found, load it.  May require other helpers
      paths.each do |path|
        next if @loaded_helpers.include?(path)
        @loaded_helpers << path

        eval(@helper_bundle.helper_contents_for(path))
      end

      # restore old bundle helper.
      unless bundle.nil?
        @helper_bundle = old_helper_bundle
      end
    end

  end

end
