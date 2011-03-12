require "sproutcore/builders/chance_file"

require "fileutils"
require "chance"

module SC
  # This builder builds CSS using Chance.
  # It extends ChanceFile for the rewrite_inline_code implementation, etc.
  class Builder::Chance < Builder::ChanceFile

    def build(dst_path)
      # Force it to always stage. This will prevent it from calculating
      # twice if both build and stage are called, as build will just call
      # stage and copy the output.
      if dst_path != entry[:staging_path]
        entry.stage!
        writeline dst_path, File.read(entry[:staging_path])
        return
      end

      theme_name = entry.target.config[:css_theme]

      chance = Chance::Instance.new({ :theme => theme_name, :minify => entry[:minify] })

      entries = entry.ordered_entries || entry.source_entries

      entries.each do |entry|
        src_path = entry.stage![:staging_path]
        next unless File.exist?(src_path)

        Chance.add_file src_path
        chance.map_file(entry.filename, src_path)
      end

      css = chance.output_for entry[:chance_file]
      css = rewrite_inline_code(css)

      writeline dst_path, css

      entry[:chance] = chance
    end


  end

end
