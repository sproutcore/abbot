# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require "sproutcore/builders/base"

module SC

  # Builds a bundle_loaded.js file which MUST be the last JavaScript to load
  # in a framework.
  class Builder::BundleLoaded < Builder::Base

    def build(dst_path)
      writelines dst_path, ["; if ((typeof SC !== 'undefined') && SC.Module && SC.Module.moduleDidLoad) SC.Module.moduleDidLoad('#{entry.target[:target_name].to_s.sub(/^\//,'')}');"]
    end

  end

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
            requires: [<%= @requires.join(',') %>],
            styles:   [<%= @styles.join(',') %>],
            scripts:  [<%= @scripts.join(',') %>]
          }
        })();
      EOT

      output = ""
      
      entry.targets.each do |t|
        manifest = t.manifests[0]

        static_entry = manifest.find_entry("javascript.js")
        static_url = static_entry.cacheable_url

        module_info = t.module_info({ :debug => entry[:debug], :test => entry[:test], :theme => entry[:theme], :variation => entry[:variation] })

        module_info[:js_urls] = [static_url]

        output << eruby.evaluate({
          :target_name => t[:target_name].to_s.sub(/^\//,''),
          :requires => module_info[:requires].map{ |t| "'#{t[:target_name].to_s.sub(/^\//,'')}'" },
          :styles   => module_info[:css_urls].map{ |url| "'#{url}'" },
          :scripts  => module_info[:js_urls].map{  |url| "'#{url}'" }
        })
      end
      writelines dst_path, [output]
    end

  end

end
