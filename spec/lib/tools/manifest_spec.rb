require "spec_helper"

describe SC::Tools do
  describe "utils" do
    it "retrieves allowed keys using get_allowed_keys" do
      SC::Tools.class_eval do
        get_allowed_keys('a,b    ,  c,d').should == [:a,:b,:c,:d]
      end
    end
  end
end
