# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009-2011 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

# For all those working in internet cafes...
# We feel for you. Go to a real cafe instead. They have internet, too.
module SC
  module Rack
    class RestrictIP
      def initialize(app, allow_ips=[])
        @app = app
        @allow = allow_ips
      end
      
      # checks if an IP, such as 127.0.0.1, matches a mask, such as 127.*.*.*
      def ip_is_valid(ip, mask)
        ip_parts = ip.split('.')
        mask_parts = mask.split('.')
        
        if mask_parts.length != 4
          SC.logger.fatal "Invalid IP mask: #{mask}\n"
          exit
        end
        
        ip_idx = 0
        mask_parts.each {|mask_part|
          ip_part = ip_parts[ip_idx]
          
          # * means anything matches
          if mask_part == '*'
            next
          end
          
          if ip_part != mask_part
            return false
          end
          
          ip_idx = ip_idx + 1
        }
        
        return true
      end
    
      def call(env)
        ip = env['REMOTE_ADDR']
        
        is_valid = false
        @allow.each {|mask|
          if ip_is_valid(ip, mask)
            is_valid = true
            break
          end
        }
        
        if is_valid
          return @app.call(env)
        else
          SC.logger << "Blocked connection attempt by ip: #{ip}\n"
          return [403, { 'Content-Type' => 'text/plain' }, "YOU CANNOT BEEZ HERE."]
        end
      end
    end
  end
end