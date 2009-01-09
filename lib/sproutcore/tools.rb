require 'thor'

module SC

  # The tools module contain the classes that make up the command line tools
  # available from SproutCore. In general, each command line tool has a peer
  # class hosted in this module that implements the primary user interface.
  #
  # Internally SproutCore tools that chain together subtools (such as 
  # sc-build) will actually call these classes directly instead of taking the
  # time to instantiate a whole new process. 
  #
  # Each Tool class is implemented as a Thor subclass.  You can override 
  # methods in these classes in your own ruby code if you want to make a 
  # change to how these tools execute.  Any ruby you place in your Buildfile
  # to modify one of these classes will actually be picked up by the 
  # tool itself when it runs.
  #
  module Tools
    
  end
  
end

SC.require_all_libs_relative_to(__FILE__)
