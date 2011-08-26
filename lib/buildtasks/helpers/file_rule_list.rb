require "json"
require "buildtasks/helpers/file_rule"

module SproutCore
  
  # The FileRuleList applies a list of ordered rules to a file path to
  # determine whether to reject it or approve it.
  #
  # The FileRuleList actually manages multiple sets of rules, separated by
  # target name.
  #
  # The FileRuleList can read in JSON files (in either Allow or Deny mode)
  # and SproutCore Approve Lists.
  #
  #     To read JSON: 
  #     list.read_json(path, :allow)
  #
  #     To read Approve Lists
  #     list.read(path)
  #
  class FileRuleList
    attr_accessor :allow_by_default, :ignore_list
    
    ALWAYS_ACCEPTED_FILE_TYPES= [
      '.manifest',
      '.htm',
      '.html',
      '.rhtml',
      '.png',
      '.jpg',
      '.jpeg',
      '.gif'
    ]
    
    def initialize
      @allow_by_default = false
      @ignore_list = true
      @file_rule_lists = {}
    end
    
    def add_rule(target, rule)
      @ignore_list = false
      
      @file_rule_lists[target] ||= []
      @file_rule_lists[target] << rule
    end
    
    def include?(target, file)
      return true if @ignore_list
      return true if ALWAYS_ACCEPTED_FILE_TYPES.include?(File.extname file)
      
      list = @file_rule_lists[target.to_s]
      return @allow_by_default if list.nil?
      
      approved = @allow_by_default
      list.each {|rule|
        _approved = rule.include? file
        approved = _approved if not _approved.nil?
      }
      
      approved
    end
    
    #
    # Read methods
    #
    def read_json(path, mode)
      @ignore_list = false
      
      if mode != :allow and mode != :deny
        raise "read_json must be given either mode :allow or mode :deny"
      end
      
      content = JSON.parse(File.read(path))
      
      content.each do |target, list|
        list = [list] if list.kind_of?(String)
        
        list.each do |expression|
          rule = SproutCore::FileRule.new(expression, mode)
          add_rule(target, rule)
        end
        
      end
    end
    
    def read(path)
      @ignore_list = false
      
      mode = :allow
      target = nil
      line_number = 0
      File.new(path).each_line {|line|
        line_number += 1
        
        line.strip!
        next if line == ""
        next if line =~ /^#/
        
        target_match = /^TARGET\s+(?<target>[^\s]+)\s*$/.match line
        if target_match
          target = target_match[:target]
          mode = :allow
          next
        end
        
        if target.nil?
          raise "Expected TARGET (target name) in Accept list at #{path}, line #{line_number}"
        end
        
        mode_match = /^(?<mode>ALLOW|DENY)(\s+(?<what>.*))?\s*$/i.match line
        if mode_match
          _mode = mode_match[:mode].downcase
          _mode = (_mode == "allow" ? :allow : :deny)
          
          if mode_match[:what]
            exp = mode_match[:what]
            exp = ".*" if exp == "all"
            rule = SproutCore::FileRule.new(exp, _mode)
            
            add_rule target, rule
          else
            mode = _mode
          end
          
          next
        end
        
        match = /(?<expression>.*)$/.match(line)
        raise "Invalid rule: #{line}" if match.nil?

        rule = SproutCore::FileRule.new(match[:expression], mode)
        add_rule target, rule
      }
    end
  end
end
