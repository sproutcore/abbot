require 'fileutils'

module SC

  # This build can compile a Sass stylesheet.  At this point it does no
  # further processing than simply executing the Sass.  It would be nice to 
  # add support for sc_static and other directives at some point.
  #
  class Builder::Sass < Builder
    
    def build(dst_path)
      begin
        require 'sass'
      rescue
        raise "Cannot compile #{entry.source_path} because sass is not installed.  Please try 'sudo gem install haml' and try again"
      end

      begin
        content = readlines(entry.source_path)*''
        content = ::Sass::Engine.new(content).render
        writelines dst_path, [content]
      rescue Exception => e
        
        # explain sass syntax error a bit more...
        if e.is_a? Sass::SyntaxError
          e_string = "#{e.class}: #{e.message}"
          e_string << "\non line #{e.sass_line}"
          e_string << " of #{@entry.source_path}"
          if File.exists?(@entry.source_path)
            e_string << "\n\n"
            min = [e.sass_line - 5, 0].max
            File.read(@entry.source_path).rstrip.split("\n")[
              min .. e.sass_line + 5
            ].each_with_index do |line, i|
              e_string << "#{min + i + 1}: #{line}\n"
            end # File.read
          end # if File.exists?
          raise e_string
        else
          raise e # reraise
        end 
      end # rescue
    end # def
    
  end
  
end
