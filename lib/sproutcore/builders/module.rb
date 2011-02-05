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
          SC.MODULE_INFO[target_name] = {
            dependencies:[<%= @dependencies.join(',') %>],
            styles:[<%= @styles.join(',') %>],
            scriptURL:'<%= @script %>',
            stringURL:'<%= @string %>'<% if @prefetched %>,
            isPrefetched: YES
            <% end %>
          }
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

        output << eruby.evaluate({
          :target_name => t[:target_name].to_s.sub(/^\//,''),
          :dependencies    => module_info[:requires].map{ |t| "'#{t[:target_name].to_s.sub(/^\//,'')}'" },
          :styles      => module_info[:css_urls].map{ |url| "'#{url}'" },
          :script      => script_url,
          :string      => string_url,
          :prefetched  => t[:prefetched_module]
        })
      end
      writelines dst_path, [output]
    end

  end

end
