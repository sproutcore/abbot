
module SC
  class Tools
    
    ################################################
    ## COMMAND LINE  
    ##
    
    desc "build-number TARGET", "Computes a build number for the target"
    def build_number(*targets)
      target = requires_target!(*targets)
      $stdout << target.build_number
    end

  end
end
