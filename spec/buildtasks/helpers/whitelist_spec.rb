require "spec_helper"

describe Whitelist do
  describe "#acceptable_file?" do
    it "is false when the folder is mentioned, but the file is not listed" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => ['something_else.js']})

      @whitelist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_false
    end

    it "is true when the file is explicitly mentioned in the specification" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => ['something.js']})

      @whitelist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_true
    end

    it "is true when the folder is mentioned and it allows a regular expression that matches" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => ['.*']})

      @whitelist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_true
    end

    it "is true when the folder is mentioned and it allows all files inside" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => '.*'})

      @whitelist.acceptable_file?('/sproutcore/bootstrap/something.js').should be_true
    end

    it "is true when the folder is mentioned and the file is listed, but it is not the only one" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => ['something.js', 'else.js']})

      @whitelist.acceptable_file?('/sproutcore/bootstrap/else.js').should be_true
    end

    it "is true when the file is a manifest file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.manifest').should be_true
    end

    it "is true when the file is a htm file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.htm').should be_true
    end

    it "is true when the file is a html file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.html').should be_true
    end

    it "is true when the file is a rhtml file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.rhtml').should be_true
    end

    it "is true when the file is a png file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.png').should be_true
    end

    it "is true when the file is a jpg file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.jpg').should be_true
    end

    it "is true when the file is a jpeg file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.jpeg').should be_true
    end

    it "is true when the file is a gif file" do
      @whitelist = Whitelist.new({'/sproutcore/bootstrap' => 'something.js'})

      @whitelist.acceptable_file?('something.gif').should be_true
    end
  end
end
