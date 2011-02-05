# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require 'singleton'
require 'time'

module SC

  # EarlyTime is a fake timestamp that occurs _before_ any other time value.
  # Borrowed from Rake 0.8.3
  class EarlyTime < Time
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
