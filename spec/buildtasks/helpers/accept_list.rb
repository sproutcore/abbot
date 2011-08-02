require "spec_helper"

WHITELIST_PATH = File.dirname(__FILE__) + '/list.json'
ACCEPT_LIST_PATH = File.dirname(__FILE__) + '/accept_list'


module FileRuleListSpec
  class YesRule
    def include?(f)
      true
    end
  end
  
  class NoRule
    def include?(f)
      false
    end
  end
end

describe "FileRuleList" do
  it "includes if ignore_list has not been unset" do
    list = SproutCore::FileRuleList.new
    list.include?("target1", "some_file.js").should be_true
  end
  
  it "does not include when there are no rules" do
    list = SproutCore::FileRuleList.new
    list.ignore_list = false
    list.include?("target1", "some_file.js").should be_false
  end
  
  it "includes when there is an allow rule" do
    list = SproutCore::FileRuleList.new
    list.add_rule("target1", FileRuleListSpec::YesRule.new)
    list.include?("target1", "some_file.js").should be_true
  end
  
  it "does not include when there is both a yes and a no rule" do
    list = SproutCore::FileRuleList.new
    list.add_rule("target1", FileRuleListSpec::YesRule.new)
    list.add_rule("target1", FileRuleListSpec::NoRule.new)
    list.include?("target1", "some_file.js").should be_false
  end
  
  it "includes when there is a yes rule, followed by a no, followed by a yes" do
    list = SproutCore::FileRuleList.new
    list.add_rule("target1", FileRuleListSpec::YesRule.new)
    list.add_rule("target1", FileRuleListSpec::NoRule.new)
    list.add_rule("target1", FileRuleListSpec::YesRule.new)
    list.include?("target1", "some_file.js").should be_true
  end
  
  it "maintains separate lists for each target" do
    list = SproutCore::FileRuleList.new
    list.add_rule("target1", FileRuleListSpec::YesRule.new)
    list.add_rule("target2", FileRuleListSpec::NoRule.new)
    list.include?("target1", "some_file.js").should be_true
    list.include?("target2", "some_file.js").should be_false
  end
  
  it "obeys allow_by_default" do
    list = SproutCore::FileRuleList.new
    list.allow_by_default = true
    list.include?("target1", "some_file.js").should be_true
  end
  
  it "always allows the ALWAYS_ACCEPTED_FILE_TYPES, no matter what" do
    list = SproutCore::FileRuleList.new
    list.add_rule("target1", FileRuleListSpec::NoRule.new)
    
    [
      '.manifest',
      '.htm',
      '.html',
      '.rhtml',
      '.png',
      '.jpg',
      '.jpeg',
      '.gif'
    ].each {|name|
      list.include?("target1", "a_file#{name}").should be_true
    }
    
    list.include?("target1", "some_file.js").should be_false
  end
    
  

  
  describe "#read_json" do
    it "reads in allow mode properly" do
      list = SproutCore::FileRuleList.new
      list.read_json(WHITELIST_PATH, :allow)
      
      list.include?("/target1/abc", "file1.js").should be_true
      list.include?("/target1/abc", "file3.js").should be_false
      list.include?("/target1/def", "file2.js").should be_false
      list.include?("/target1/def", "file4.js").should be_true
    end
    
    it "reads in deny mode properly" do
      list = SproutCore::FileRuleList.new
      list.allow_by_default = true
      list.read_json(WHITELIST_PATH, :deny)
      
      list.include?("/target1/abc", "file1.js").should be_false
      list.include?("/target1/abc", "file3.js").should be_true
      list.include?("/target1/def", "file2.js").should be_true
      list.include?("/target1/def", "file4.js").should be_false
    end
  end
  
  describe "#read" do
    it "reads the list properly" do
      list = SproutCore::FileRuleList.new
      list.read(ACCEPT_LIST_PATH)
      
      list.include?("/target1/abc", "file1.js").should be_true
      list.include?("/target1/abc", "file3.js").should be_false
      
      # Target1/def denies exactly one file: file2.js. Everything else is allowed.
      list.include?("/target1/def", "file2.js").should be_false
      list.include?("/target1/def", "fadjfhakljdf.js").should be_true
    end
  end
end

