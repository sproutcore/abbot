require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::ChanceJavaScript < Builder::Base

    def build(dst_path)
      entries = entry.ordered_entries || entry.source_entries

      javascript = entries.map {|entry|
        chance = entry[:chance]
        src = ""
        src = chance.files["chance.js"] unless chance.nil?

        src
      }.join("\n")

      writeline dst_path, javascript
    end

  end

end

