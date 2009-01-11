module SproutCore
  
  # Builder classes implement the more complex algorithms for building 
  # resources in SproutCore such as building HTML, JavaScript or CSS.  
  # Builders are usually invoked from within build tasks which are, in-turn,
  # selected by the manifest.
  #
  module Builder
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
