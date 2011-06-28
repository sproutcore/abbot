# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2011 Apple Inc.
# ===========================================================================

# The CSS Split module splits mammoth CSS files into smaller chunks
# by the count of selectors. As soon as a maximum number of selectors
# are reached, a new string of CSS will be created.
# 
# We need this because IE only allows ~4096 selectors per file.
#
# @author Alex Iskander
module SC::Helpers
  
  module SplitCSS
    # IE allows up to 4094 or so. To be safe, we'll stick with 4080.
    RULE_LIMIT = 4000
  
    # Works like a normal string split method, except that it splits by
    # number of rules: each time the RULE_LIMIT is reached, a new string
    # will be started
    def self.split_css(css) 
      idx = 0
      len = css.length
    
      in_string = false
      string_start_character = "" # The quote character that began the string
    
      in_comment = false
      in_selector = false

      # We have to do multiple depth so that we handle things like webkit animations
      # properly. Otherwise we'll get into a bad state
      rule_depth = 0
    
      last_rule_end = 0
    
      current_string = ""
      list = []
    
      current_selector_count = 0
      selectors_in_rule = 0
      total_selector_count = 0
    
      # Loop through the characters
      while idx < len
        c = css[idx]
      
        # also, get the next character so we can check if we're beginning or ending
        # a comment.
        n = css[idx + 1]
      
        # If we are in a string, check to see if we are at the end yet.
        if in_string
          if c == "\\"
            # skip not just this character (done below) but the next one too.
            idx += 1
          elsif c == string_start_character
            in_string = false
          end
        
          idx +=1
          next
        end
      
        # If we are in a comment, check to see if we are at the end yet
        if in_comment
          if c == '*' and n == '/'
            in_comment = false
          
            # In this case, we want to skip both this one and the next one (below)
            idx += 1
          end
        
          idx += 1
          next
        end
      
        # Check to see if we are beginning a comment
        if c == "/" and n == "*"
          idx += 2
          in_comment = true
          next
        end
      
        # check to see if we are beginning a string
        if c == '"' or c == "'"
          # NOTE: strings can, in some cases, be inside of selectors.
          in_string = true
          string_start_character = c
        
          idx += 1
          next
        end
      
        # If we are in a rule, check to see if we are ending that rule.
        if rule_depth > 0
          if c == '}'
            rule_depth -= 1
          
        
            if rule_depth == 0
              # Write the rule to the string, starting from where the last rule
              # ended, going to where this one ends.
              current_string << css[last_rule_end..idx] + "\n"
          
              # Also keep reset the number of selectors inside the new rule,
              # so we can keep an accurate count for next time.
              selectors_in_rule = 0
          
              last_rule_end = idx + 1
            end
          
            idx += 1
            next
          end
        end
      
        # Check to see if we are beginning a rule
        if c == "{"
          # Beginning a rule ends the current selector
          in_selector = false
        
          rule_depth += 1
          idx += 1
          next
        end
      
        if rule_depth > 0
          idx += 1
          next
        end
      
        # ignore all whitespace
        if c =~ /\s/
          idx += 1
          next
        end
      
        if c == '@'
          current_selector_count -= 1
          total_selector_count -= 1
          selectors_in_rule -= 1
          idx += 1
          next
        end
      
        # We're here, so we have a non-whitespace character
        # If it is a comma, we are no longer in a selector.
        if c == ','
          in_selector = false
          idx += 1
          next
        end
      
        # And otherwise, we are now in a selector so need to increment the selector count...
        if not in_selector
          in_selector = true
        
          current_selector_count += 1
          selectors_in_rule += 1
          total_selector_count += 1
      
          # If there are too many selectors, begin a new string
          if current_selector_count > SplitCSS::RULE_LIMIT
            list << current_string
          
            current_string = ""
            current_selector_count = selectors_in_rule
          end
        end
      
        idx += 1
      end
    
      # Add any remainder
      current_string << css[last_rule_end...idx]
      list << current_string if current_string.length > 0
    
      list
    end
  end

end