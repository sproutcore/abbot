require 'singleton'

module SC
  
  # EarlyTime is a fake timestamp that occurs _before_ any other time value.
  # Borrowed from Rake 0.8.3
  class EarlyTime
    include Comparable
    include Singleton

    def <=>(other)
      -1
    end

    def to_s
      "<EARLY TIME>"
    end
  end

  EARLY = EarlyTime.instance

end  