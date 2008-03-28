# This version of jsmin has been adapted for use in a module.

# jsmin.rb 2007-07-20
# Author: Uladzislau Latynski
# This work is a translation from C to Ruby of jsmin.c published by
# Douglas Crockford.  Permission is hereby granted to use the Ruby
# version under the same conditions as the jsmin.c on which it is
# based.
#
# /* jsmin.c
#    2003-04-21
#
# Copyright (c) 2002 Douglas Crockford  (www.crockford.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# The Software shall be used for Good, not Evil.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module SproutCore

  class JSMin
    EOF = -1
    
    # this will minify a single line 
    def self.run(str)
      minifier = SproutCore::JSMin.new(str)
      minifier.jsmin
      minifier.stdout
    end
    
    def initialize(str) 
      @theA = ""
      @theB = ""
      @str = str || ''
      @loc = 0
      @stdout = ''
    end

    def stdin_getc
      ret = @str.nil? || (@loc >= @str.size) ? nil : @str[@loc]
      @loc += 1
      return ret 
    end
    
    def stdin_ungetc(str)
      @loc -= 1
      @loc = 0 if @loc < 0
    end
    
    def stdout_write(chr)
      @stdout << chr
    end
    
    def stdout
      return @stdout
    end
    
#### JSMIN
## To update, replace the text below with the latest jsmin.rb. Then replace:
## $theA => @theA, $theB => @theB, 
## $stdin.getc => stdin_getc, $stdin.ungetc => stding_ungetc, 
## $stdout.write => stdout_write

    # isAlphanum -- return true if the character is a letter, digit, 
    # underscore, dollar sign, or non-ASCII character
    def isAlphanum(c)
      return false if !c || c == EOF
      return ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
      (c >= 'A' && c <= 'Z') || c == '_' || c == '$' ||
      c == '\\' || c[0] > 126)
    end

    # get -- return the next character from stdin. Watch out for lookahead. 
    # If the character is a control character, translate it to a space or 
    # linefeed.
    def get()
      c = stdin_getc
      return EOF if(!c)
      c = c.chr
      return c if (c >= " " || c == "\n" || c.unpack("c") == EOF)
      return "\n" if (c == "\r")
      return " "
    end

    # Get the next character without getting it.
    def peek()
      lookaheadChar = stdin_getc
      stdin_ungetc(lookaheadChar)
      return lookaheadChar.chr
    end

    # mynext -- get the next character, excluding comments.
    # peek() is used to see if a '/' is followed by a '/' or '*'.
    def mynext()
      c = get
      if (c == "/")
        if(peek == "/")
          while(true)
            c = get
            if (c <= "\n")
              return c
            end
          end
        end
        if(peek == "*")
          get
          while(true)
            case get
            when "*"
              if (peek == "/")
                get
                return " "
              end
            when EOF
              raise "Unterminated comment"
            end
          end
        end
      end
      return c
    end


    # action -- do something! What you do is determined by the argument: 1
    # Output A. Copy B to A. Get the next B. 2 Copy B to A. Get the next B.
    # (Delete A). 3 Get the next B. (Delete B). action treats a string as a
    # single character. Wow! action recognizes a regular expression if it is
    # preceded by ( or , or =.
    def action(a)
      if(a==1)
        stdout_write @theA
      end
      if(a==1 || a==2)
        @theA = @theB
        if (@theA == "\'" || @theA == "\"")
          while (true)
            stdout_write @theA
            @theA = get
            break if (@theA == @theB)
            raise "Unterminated string literal" if (@theA <= "\n")
            if (@theA == "\\")
              stdout_write @theA
              @theA = get
            end
          end
        end
      end
      if(a==1 || a==2 || a==3)
        @theB = mynext
        if (@theB == "/" && (@theA == "(" || @theA == "," || @theA == "=" ||
          @theA == ":" || @theA == "[" || @theA == "!" ||
          @theA == "&" || @theA == "|" || @theA == "?" ||
          @theA == "{" || @theA == "}" || @theA == ";" ||
          @theA == "\n"))
          stdout_write @theA
          stdout_write @theB
          while (true)
            @theA = get
            if (@theA == "/")
              break
            elsif (@theA == "\\")
              stdout_write @theA
              @theA = get
            elsif (@theA <= "\n")
              raise "Unterminated RegExp Literal"
            end
            stdout_write @theA
          end
          @theB = mynext
        end
      end
    end

    # jsmin -- Copy the input to the output, deleting the characters which are
    # insignificant to JavaScript. Comments will be removed. Tabs will be
    # replaced with spaces. Carriage returns will be replaced with linefeeds.
    # Most spaces and linefeeds will be removed.
    def jsmin
      @theA = "\n"
      action(3)
      while (@theA != EOF)
        case @theA
        when " "
          if (isAlphanum(@theB))
            action(1)
          else
            action(2)
          end
        when "\n"
          case (@theB)
          when "{","[","(","+","-"
            action(1)
          when " "
            action(3)
          else
            if (isAlphanum(@theB))
              action(1)
            else
              action(2)
            end
          end
        else
          case (@theB)
          when " "
            if (isAlphanum(@theA))
              action(1)
            else
              action(3)
            end
          when "\n"
            case (@theA)
            when "}","]",")","+","-","\"","\\", "'", '"'
              action(1)
            else
              if (isAlphanum(@theA))
                action(1)
              else
                action(3)
              end
            end
          else
            action(1)
          end
        end
      end
    end

################ END JSMIN
  end

end
