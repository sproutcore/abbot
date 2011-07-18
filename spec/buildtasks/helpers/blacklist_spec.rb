require "spec_helper"

describe Blacklist do
  describe "#acceptable_file?" do
    it "is true when the folder is mentioned, but the file is not listed" do
      @blacklist = Blacklist.new({'/sproutcore/bootstrap' => ['something_else.js']})

      @blacklist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_true
    end

    it "is false when the file is explicitly mentioned in the specification" do
      @blacklist = Blacklist.new({'/sproutcore/bootstrap' => ['something.js']})

      @blacklist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_false
    end

    it "is false when the folder is mentioned and it excludes a regular expression that matches" do
      @blacklist = Blacklist.new({'/sproutcore/bootstrap' => ['.*']})

      @blacklist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_false
    end

    it "is false when the folder is mentioned and it excludes all files inside" do
      @blacklist = Blacklist.new({'/sproutcore/bootstrap' => '.*'})

      @blacklist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_false
    end

    it "is false when the folder is mentioned and the file is listed, but it is not the only one" do
      @blacklist = Blacklist.new({'/sproutcore/bootstrap' => ['something.js', 'else.js']})

      @blacklist.acceptable_file?('/sproutcore/bootstrap/else.js').should be_false
    end
  end
end
