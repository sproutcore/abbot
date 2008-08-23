module SproutCore
  module Renderers

    class Sass

      def self.compile(entry, content)
        require 'sass'
        begin
          ::Sass::Engine.new(content).render
        rescue Exception => e
          e_string = "#{e.class}: #{e.message}"
          if e.is_a? Sass::SyntaxError
            e_string << "\non line #{e.sass_line}"
            e_string << " of #{entry.source_path}"
            if File.exists?(entry.source_path)
              e_string << "\n\n"
              min = [e.sass_line - 5, 0].max
              File.read(entry.source_path).rstrip.split("\n")[
                min .. e.sass_line + 5
              ].each_with_index do |line, i|
                e_string << "#{min + i + 1}: #{line}\n"
              end
            end
          end
<<END
/*
#{e_string}

Backtrace:\n#{e.backtrace.join("\n")}
*/
body:before {
  white-space: pre;
  font-family: monospace;
  content: "#{e_string.gsub('"', '\"').gsub("\n", '\\A ')}"; }
END
        end
      end

    end

  end
end