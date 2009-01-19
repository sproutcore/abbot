module SC

  # Builds an HTML files.  This will setup an HtmlContext and then invokes
  # the render engines for each source before finally rendering the layout.
  class Builder::Html < Builder
    
    def build(dst_path)
      ### TODO
      lines = readlines(entry.source_path).map { |l| rewrite_inline_code(l) }
      writelines dst_path, lines
    end
    
  end
  
end
