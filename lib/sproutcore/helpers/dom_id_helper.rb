module SC
  module Helpers

    module DomIdHelper
      @@tick = 0

      def dom_id!(type="id")
        @@tick += 1
        return "#{type}_#{(Time.now.to_i + @@tick)}"
      end
    end

  end
end