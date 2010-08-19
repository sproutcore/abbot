# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require 'cgi'
require 'erb'

# Borrowed from Rails 2.0.2

module SC
  module Helpers #:nodoc:
    # Use these methods to generate HTML tags programmatically when you can't use
    # a Builder. By default, they output XHTML compliant tags.
    module TagHelper
      include ERB::Util

      # Returns an empty HTML tag of type +name+ which by default is XHTML
      # compliant. Setting +open+ to true will create an open tag compatible
      # with HTML 4.0 and below. Add HTML attributes by passing an attributes
      # hash to +options+. For attributes with no value like (disabled and
      # readonly), give it a value of true in the +options+ hash. You can use
      # symbols or strings for the attribute names.
      #
      #   tag("br")
      #    # => <br />
      #   tag("br", nil, true)
      #    # => <br>
      #   tag("input", { :type => 'text', :disabled => true })
      #    # => <input type="text" disabled="disabled" />
      def tag(name, options = nil, open = false)
        "<#{name}#{tag_options(options) if options}" + (open ? ">" : " />")
      end

      # Returns an HTML block tag of type +name+ surrounding the +content+. Add
      # HTML attributes by passing an attributes hash to +options+. For attributes
      # with no value like (disabled and readonly), give it a value of true in
      # the +options+ hash. You can use symbols or strings for the attribute names.
      #
      #   content_tag(:p, "Hello world!")
      #    # => <p>Hello world!</p>
      #   content_tag(:div, content_tag(:p, "Hello world!"), :class => "strong")
      #    # => <div class="strong"><p>Hello world!</p></div>
      #   content_tag("select", options, :multiple => true)
      #    # => <select multiple="multiple">...options...</select>
      #
      # Instead of passing the content as an argument, you can also use a block
      # in which case, you pass your +options+ as the second parameter.
      #
      #   <% content_tag :div, :class => "strong" do -%>
      #     Hello world!
      #   <% end -%>
      #    # => <div class="strong"><p>Hello world!</p></div>
      def content_tag(name, content_or_options_with_block = nil, options = nil, &block)
        if block_given?
          options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
          content = capture(&block)
          content_tag = content_tag_string(name, content, options)
          block_is_within_action_view?(block) ? concat(content_tag, block.binding) : content_tag
        else
          content = content_or_options_with_block
          content_tag_string(name, content, options)
        end
      end

      # Returns a CDATA section with the given +content+.  CDATA sections
      # are used to escape blocks of text containing characters which would
      # otherwise be recognized as markup. CDATA sections begin with the string
      # <tt><![CDATA[</tt> and end with (and may not contain) the string <tt>]]></tt>.
      #
      #   cdata_section("<hello world>")
      #    # => <![CDATA[<hello world>]]>
      def cdata_section(content)
        "<![CDATA[#{content}]]>"
      end

      # Returns the escaped +html+ without affecting existing escaped entities.
      #
      #   escape_once("1 > 2 &amp; 3")
      #    # => "1 &lt; 2 &amp; 3"
      def escape_once(html)
        fix_double_escape(html_escape(html.to_s))
      end

      # Simple link_to can wrap a passed string with a link to a specified
      # target or static asset.  If you pass a block then the block will be
      # invoked and its resulting content linked.  You can also pass
      # :popup, :title, :id, :class, and :style
      def link_to(content, opts=nil, &block)
        if block_given?
          concat(link_to(capture(&block), content), block.binding);
          return ''
        end

        if !content.instance_of?(String) && opts.nil?
          opts = content
          content = nil
        end

        opts = { :href => opts } if opts.instance_of? String
        opts = HashStruct.new(opts)
        html_attrs = HashStruct.new
        is_target = false

        if opts.href
          html_attrs.href = opts.href
        elsif opts.target

          is_target = (target.target_name.to_sym == "/#{opts.target.to_s}".to_sym)

          # supply title if needed
          if content.nil?
            cur_target = is_target ? target : target.target_for(opts.target)
            content = title(cur_target) if cur_target
            content = opts.target if content.nil?
          end

          # if current==false, then don't link if current target matches
          if !opts.current.nil? && (opts.current==false) && is_target
            return %(<span class="anchor current">#{content}</span>)
          end

          html_attrs.href = sc_target(opts.target, :language => opts.language)
        elsif opts.static
          html_attrs.href = sc_static(opts.static, :language => opts.language)
        end

        if opts.popup
          popup = opts.popup
          html_attrs.target = popup.instance_of?(String) ? popup : '_blank'
        end

        %w[title id class style].each do |key|
          html_attrs[key] = opts[key] if opts[key]
        end

        # add "current" class name
        if is_target
          html_attrs[:class] = [html_attrs[:class], 'current'].compact.join(' ')
        end

        ret = ["<a "]
        html_attrs.each { |k,v| ret << [k,'=','"',v,'" '].join('') }
        ret << '>'
        ret << content
        ret << '</a>'
        return ret.join('')
      end

      private
        def content_tag_string(name, content, options)
          tag_options = options ? tag_options(options) : ""
          "<#{name}#{tag_options}>#{content}</#{name}>"
        end

        def tag_options(options)
          cleaned_options = convert_booleans(options.stringify_keys.reject {|key, value| value.nil?})
          ' ' + cleaned_options.map {|key, value| %(#{key}="#{escape_once(value)}")}.sort * ' ' unless cleaned_options.empty?
        end

        def convert_booleans(options)
          %w( disabled readonly multiple ).each { |a| boolean_attribute(options, a) }
          options
        end

        def boolean_attribute(options, attribute)
          options[attribute] ? options[attribute] = attribute : options.delete(attribute)
        end

        # Fix double-escaped entities, such as &amp;amp;, &amp;#123;, etc.
        def fix_double_escape(escaped)
          escaped.gsub(/&amp;([a-z]+|(#\d+));/i) { "&#{$1};" }
        end

        def block_is_within_action_view?(block)
          eval("defined? _erbout", block.binding)
        end
    end
  end
end
