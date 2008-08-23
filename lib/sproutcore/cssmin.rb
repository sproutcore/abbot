# module and class name have been modified
#
# == MIT License
# See http://code.google.com/p/rainpress/
#
# == About
#
# Rainpress is a compressor for CSS. It's written in ruby, but should not be 
# limited to ruby projects.
#
# Rainpress does not apply common compression algorithms like gzip, it removes 
# unnecessary characters and replaces some attributes with a shorter equivalent 
# name.
#
# == Links
#
# * {Rainpress Website}[http://rainpress.xhochy.com/]
# * {SVN repository}[http://code.google.com/p/rainpress/source]
# * {Bugtracker}[https://bugs.launchpad.net/rainpress/]
# * {Wiki}[http://code.google.com/p/rainpress/w/list]
# * {Translations}[https://translations.launchpad.net/rainpress/]
# * {XhochY Weblog (for Announcements about Rainpress)}[http://xhochy.org/en/]
# * {Mailinglist}[http://groups.google.com/group/xy-oss-projects-discussion]
# * {Continous Integration Builds and Tests}[http://cruisecontrol-rb.xhochy.com/builds/rainpress]
# * {Freshmeat Record}[http://freshmeat.net/projects/rainpress]
module SproutCore

  # == Information
  #
  # This is the main class of Rainpress, create an instance of it to compress
  # your CSS-styles.
  #
  # == Simple Usage
  #
  #   packer = SproutCore::CSSPacker.new
  #   compressed_style = packer.compress(style)
  class CSSPacker
  
    # Use always this functions if you want to compress your CSS-style
    #
    # <b>Options:</b>
    #
    # * <tt>:preserveComments</tt> - if set to true, comments will not be 
    #   removed
    # * <tt>:preserveNewline</tt> - if set to true, newlines will not be removed
    # * <tt>:preserveSpaces</tt> - if set to true, spaces will not be removed
    # * <tt>:preserveColors</tt> - if set to true, colors will not be modified
    # * <tt>:skipMisc</tt> - if set to true, miscellaneous compression parts
    #   will be skipped
    def compress(style, options = {})
      # remove comments
      style = remove_comments(style) unless options[:preserveComments]
    	
  	  # remove newlines
      style = remove_newlines(style) unless options[:preserveNewlines]
    	
	  # remove unneeded spaces
      style = remove_spaces(style) unless options[:preserveSpaces]
    	
	  # replace colours with shorter names
      style = shorten_colors(style) unless options[:preserveColors]
      
      # make all other things
      style = do_misc(style) unless options[:skipMisc]
      
	  style
	end
  
    # Remove all comments out of the CSS-Document
  	def remove_comments(script)
      input = script
      script = ''
      
      while input.length > 0 do
        pos = input.index("/*");
        
        # No more comments
        if pos == nil
          script += input
          input = '';
        else # Comment beginning at pos
          script += input[0..(pos-1)] if pos > 0 # only append text if there is some
          input = input[(pos+2)..-1]
          # Comment ending at pos
          pos = input.index("*/")
          input = input[(pos+2)..-1]
        end
      end
      
      # return
  		script
  	end

    # Remove all newline characters
  	def remove_newlines(script)
  		script.gsub(/\n|\r/,'')
  	end
  	
    # 1. Turn mutiple spaces into a single
    # 2. Remove spaces around ;:{},
    # 3. Remove tabs
    def remove_spaces(script)
  	  script = script.gsub(/(\s(\s)+)/, ' ')
      script = script.gsub(/\s*;\s*/,';')
      script = script.gsub(/\s*:\s*/,':')
      script = script.gsub(/\s*\{\s*/,'{')
      script = script.gsub(/\s*\}\s*/,'}')
      script = script.gsub(/\s*,\s*/,',')
      script.gsub("\t",'');
  	end
  	
  	# Replace color values with their shorter equivalent
  	#
  	# 1. Turn rgb(,,)-colors into #-values
  	# 2. Shorten #AABBCC down to #ABC
  	# 3. Replace names with their shorter hex-equivalent
  	#    * white -> #fff
   	#    * black -> #000
  	# 4. Replace #-values with their shorter name
  	#    * #f00 -> red
  	def shorten_colors(style)
  	  # rgb(50,101,152) to #326598
      style = style.gsub(/rgb\s*\(\s*([0-9,\s]+)\s*\)/) do |match|
        out = '#'
        $1.split(',').each do |num|
          if num.to_i < 16 
            out += '0'
          end
          out += num.to_i.to_s(16) # convert to hex
        end
        out
      end
      # #AABBCC to #ABC, keep if preceed by a '='
      style = style.gsub(/([^\"'=\s])(\s*)#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])/) do |match|
        out = match        
        if ($3.downcase == $4.downcase) and ($5.downcase == $6.downcase) and ($7.downcase == $8.downcase)
          out = $1 + '#' + $3.downcase + $5.downcase + $7.downcase 
        end
        out
      end
      # shorten several names to numbers
      style = style.gsub(/:[\s]*white[\s]*;/, ':#fff;')
      style = style.gsub(/:[\s]*white[\s]*\}/, ':#fff}')
      style = style.gsub(/:[\s]*black[\s]*;/, ':#000;')
      style = style.gsub(/:[\s]*black[\s]*\}/, ':#000}')
      # shotern several numbers to names
      style = style.gsub(/:[\s]*#([fF]00|[fF]{2}0000);/, ':red;')
      style = style.gsub(/:[\s]*#([fF]00|[fF]{2}0000)\}/, ':red}')
      
  	  style
    end
  
    # Do miscellaneous compression methods on the style
    def do_misc(script)
      # Replace 0(pt,px,em,%) with 0 but only when preceded by : or a white-space
      script = script.gsub(/([\s:]+)(0)(px|em|%|in|cm|mm|pc|pt|ex)/) do |match|
        match.gsub(/(px|em|%|in|cm|mm|pc|pt|ex)/,'')
      end
      # Replace 0 0 0 0; with 0.
      script = script.gsub(':0 0 0 0;', ':0;')
      script = script.gsub(':0 0 0 0}', ':0}')
      script = script.gsub(':0 0 0;', ':0;')
      script = script.gsub(':0 0 0}', ':0}')
      script = script.gsub(':0 0}', ':0}')
      script = script.gsub(':0 0;', ':0;')
      # Replace background-position:0; with background-position:0 0;
      script = script.gsub('background-position:0;', 'background-position:0 0;');
      # Replace 0.6 to .6, but only when preceded by : or a white-space
      script = script.gsub(/[:\s]0+\.(\d+)/) do |match|
        match.sub('0', '') # only first '0' !!
      end
      # Replace ;;;; with ;
      script = script.gsub(/[;]+/, ';')
      # Replace ;} with }
      script = script.gsub(';}', '}')
      # Replace background-color: with background:
      script = script.gsub('background-color:', 'background:')
      # Replace font-weight:normal; with 400, bold with 700
      script = script.gsub(/font-weight[\s]*:[\s]*normal[\s]*;/,'font-weight:400;')
      script = script.gsub(/font-weight[\s]*:[\s]*normal[\s]*\}/,'font-weight:400}')
      script = script.gsub(/font[\s]*:[\s]*normal[\s;\}]*/) do |match|
        match.sub('normal', '400')
      end
      script = script.gsub(/font-weight[\s]*:[\s]*bold[\s]*;/,'font-weight:700;')
      script = script.gsub(/font-weight[\s]*:[\s]*bold[\s]*\}/,'font-weight:700}')
      script = script.gsub(/font[\s]*:[\s]*bold[\s;\}]*/) do |match|
        match.sub('bold', '700')
      end
      
      script
    end
    
  end
  
end
