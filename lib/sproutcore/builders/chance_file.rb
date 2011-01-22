require "sproutcore/builders/base"
require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  class Builder::ChanceFile < Builder::Base

    def build(dst_path)
      entries = entry.ordered_entries || entry.source_entries
      chance_file = entry[:chance_file]

      src = entries.map {|entry|
        chance = entry[:chance]
        src = ""
        src = chance.files[chance_file] unless chance.nil?

        src
      }.join("\n")

      writeline dst_path, src
    end

  end

end


