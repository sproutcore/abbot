# THE PARSER
#
# The parser will not bother splitting into tokens. We are _a_
# step up from Regular Expressions, not a thousand steps.
#
# In short, we keep track of two things: { } and strings.
#
# Other than that, we look for @theme, slices(), and slice(),
# in their various forms.
#
# Our method is to scan until we hit a delimiter followed by any
# of the following:
#
# - @theme
# - @include slices(
# - slices(
# - slice(
#
# Options
# --------------------------------
# You may pass a few configuration options to a Chance instance:
#
# - :theme: a selector that will make up the initial value of the $theme
#   variable. For example: :theme => "ace.test-controls"
#
#
# How Slice & Slices work
# -------------------------------
# @include slice() and @include slices() are not actually responsible
# for slicing the image. They do not know the image's width or height.
#
# All that they do is determine the slice's configuration, including
# its file name, the rectangle to slice, etc.
require "stringio"


module SC::Helpers
  
  module SplitCSS
    UNTIL_SINGLE_QUOTE = /(?!\\)'/
    UNTIL_DOUBLE_QUOTE = /(?!\\)"/

    BEGIN_SCOPE = /\{/
    END_SCOPE = /\}/
    NORMAL_SCAN_UNTIL = /[^{},]+/
    
    MAX_SELECTOR_COUNT = 4000
    
    def self.split_css(input)
      scanner = StringScanner.new(input)
      
      current = ""
      ret = [current]
      
      selectors = ""
      in_selector = false
      selector_count = 0
      
      while not scanner.eos?
        # Handle any strings, etc. This also handles whitespace, strings, blah.
        # Basically, unless we see a scope, we know we are in a selector.
        selectors << handle_skip(scanner)
        
        # Handle scope
        if scanner.match?(BEGIN_SCOPE)
          # Push the current selectors
          current << selectors
          selectors = ""
          in_selector = false
          
          current << handle_scope(scanner)
          
          # For readability and reliability in certain browsers, add a newline at the end
          # of each rule.
          current << "\n"
          next
        end
        
        # Handle , -- which would mean we are finishing a selector
        if scanner.match? /,/
          selectors << scanner.scan(/,/)
          in_selector = false
          
          next
        end
        
        if not in_selector
          # At this point we MUST be in a selector.
          in_selector = true
          selector_count += 1
          
          if selector_count > MAX_SELECTOR_COUNT
            current = ""
            ret << current
            
            selector_count = 0
          end
        end
        
        # skip over anything that our tokens do not start with. We implement this differently
        # since these are ONLY selectors, and therefore we must add them to selector instead of output.
        res = scanner.scan(NORMAL_SCAN_UNTIL)
        break if scanner.eos?
        
        if res.nil?
          selectors << scanner.getch
        else
          selectors << res
        end
      end
      
      ret
    end
    
    def self.handle_scope(scanner)
      str = ""
      
      # Consume the begin scope we matched
      str << scanner.scan(BEGIN_SCOPE)
      
      while not scanner.eos?
        str << handle_skip(scanner)
        
        if scanner.match? BEGIN_SCOPE
          str << self.handle_scope(scanner)
        end
        
        if scanner.match? END_SCOPE
          str << scanner.scan(END_SCOPE)
          return str
        end
        
        str << handle_content(scanner)
      end
      
      str
    end
    
    def self.handle_content(scanner)
      str = ""
      
      res = scanner.scan(NORMAL_SCAN_UNTIL)
      if res.nil?
        str << scanner.getch
      else
        str << res
      end
      
      str
    end
    
    def self.handle_skip(scanner)
      str = ""

      while true do
        if scanner.match?(/\s+/)
          str << scanner.scan(/\s+/)
          next
        end
        if scanner.match?(/\/\*/)
          str << handle_comment(scanner)
          next
        end
        if scanner.match?(/["']/)
          str << handle_string(scanner)
          next
        end
        break
      end
      
      str
    end
    
    def self.handle_comment(scanner)
      str = '/*'
      
      scanner.pos += 2
      str << scanner.scan_until(/\*\//)
    end
    
    def self.handle_string(scanner)
      str = scanner.getch
      str += scanner.scan_until(str == "'" ? UNTIL_SINGLE_QUOTE : UNTIL_DOUBLE_QUOTE)
      
      str
    end
    
  end
end

