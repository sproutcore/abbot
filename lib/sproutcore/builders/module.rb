# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"

module SC

  # Builds a module_info.js file which MUST be run *before* the framework is
  # loaded by the application or framework doing the loading.
  class Builder::ModuleInfo < Builder::Base

    def build(dst_path)
      begin
        require 'erubis'
      rescue
        raise "Cannot render module_info.js because erubis is not installed. Try running 'sudo gem install erubis' and try again."
      end

      eruby = Erubis::Eruby.new <<-EOT
        ;(function() {
          var target_name = '<%= @target_name %>' ;
          if (!SC.MODULE_INFO) throw "SC.MODULE_INFO is not defined!" ;
          if (SC.MODULE_INFO[target_name]) return ; <%# not an error... %>

          <%# first time, so add a Hash with this target's module_info %>
          SC.MODULE_INFO[target_name] = SC.Object.create({
            dependencies:[<%= @dependencies.join(',') %>],
            styles:[<%= @styles.join(',') %>],
            styles2x: [<%= @styles2x.join(',') %>],
            scriptURL:'<%= @script %>',
            stringURL:'<%= @string %>'<% if @prefetched %>,
            isPrefetched: YES
            <% end %><% if @inlined %>,
            isLoaded: YES,
            source: <%= @source %>
            <% end %><% if @css_source %>,
            cssSource: <%= @css_source %>
            <% end %><% if @css_2x_source %>,
            css2xSource: <%= @css_2x_source %>
            <% end %>
          })
        })();
      EOT

      output = ""

      entry.targets.each do |t|
        next unless t[:target_type] == :module

        manifest = t.manifest_for(entry.manifest.variation)

        script_entry = manifest.find_entry('javascript.js')
        next if not script_entry
        script_url = script_entry.cacheable_url

        string_entry = manifest.find_entry('javascript-strings.js')
        next if not string_entry
        string_url = string_entry.cacheable_url

        module_info = t.module_info({ :variation => entry[:variation] })

        # Handle inlined modules. Inlined modules get included as strings
        # in the module info.
        source = nil, css_source = nil, css_2x_source = nil

        # if (and only if) the module is inlined, we must include the source
        # for the JS AND CSS inline as well (as strings)
        if t[:inlined_module]
          source = File.read(script_entry.stage![:staging_path]).to_json

          css_entry = manifest.find_entry('stylesheet.css')
          if css_entry
            css_path = css_entry.stage![:staging_path]

            # We must check if the file exists because there are cases where we can have
            # an entry but no file: no file is added if the file is empty, but the file
            # could be empty if all input files are empty or full of comments.
            css_source = File.read(css_path).to_json if File.exist? css_path
          end

          css_2x_entry = manifest.find_entry('stylesheet@2x.css')
          if css_2x_entry
            css_2x_path = css_2x_entry.stage![:staging_path]
            css_2x_source = File.read(css_2x_path).to_json if File.exist? css_2x_path
          end
        end

        output << eruby.evaluate({
          :target_name => t[:target_name].to_s.sub(/^\//,''),
          :dependencies    => module_info[:requires].map{ |t| "'#{t[:target_name].to_s.sub(/^\//,'')}'" },
          :styles      => module_info[:css_urls].map{ |url| "'#{url}'" },
          :styles2x    => module_info[:css_2x_urls].map {|url| "'#{url}'"},
          :script      => script_url,
          :string      => string_url,
          :source      => source,
          :inlined     => t[:inlined_module],
          :prefetched  => t[:prefetched_module],
          :css_source  => css_source,
          :css_2x_source => css_2x_source
        })
      end
      writelines dst_path, [output]
    end

  end

end
