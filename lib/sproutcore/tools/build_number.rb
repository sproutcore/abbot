# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================


module SC
  class Tools
    
    ################################################
    ## COMMAND LINE  
    ##

    desc "build-number TARGET", "Computes a build number for the target"
    def build_number(*targets)
      target = requires_target!(*targets)
      $stdout << target.prepare!.build_number
    end

  end
end
