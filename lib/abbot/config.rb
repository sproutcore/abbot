module Abbot
  
  # Knows how to load a config file.  This class supports pure Ruby versions,
  # YAML, or JSON config file formats.
  # 
  # To load a config, just use the Config.load() method, passing the bundle
  # source_root.  If no config file is found, this will still return a config
  # hash, but it will also set from_file? to false.
  #
  class Config < Hash
    
    # Load the file at the passed location
    def self.load(bundle_path) 
      
      # Look for a config file and try to determine the type...
      config_path = File.join(bundle_path, 'sc-config.yaml')
      return load_yaml(config_path, File.read(config_path)) if File.exist?(config_path)
      
      # Look for a file w/ rb extension...
      config_path = File.join(bundle_path, 'sc-config.rb')
      return load_ruby(config_path, File.read(config_path)) if File.exist?(config_path)
      
      # Look for a file w/ no extension...autodetect
      config_path = File.join(bundle_path, 'sc-config')
      if File.exist?(config_path)
        require 'yaml'
        file_contents = File.read(config_path)
        
        results = YAML::load(file_contents) rescue nil
        if !results.kind_of?(Hash)
          return load_ruby(config_path, file_contents)
        else
          return load_yaml(config_path,file_contents)
        end
      end
        
      # otherwise, empty...
      return Config.new(nil)
      
    end
    
    def self.load_yaml(path, content)
      require 'yaml'
      Config.new(path).apply_yaml(YAML::load(content))
    end
    
    def self.load_ruby(path, content)
      Config.new(path).eval_ruby(content)
    end
    
    
    def initialize(from_file=nil)
      @from_file = from_file
    end
    
    def from_file; @from_file; end

    # Merges configs.  This will walk down the keys, continuing to merge
    # hashes until none are left.
    def self.merge_config(hash1, hash2)
      ret = hash2 || hash1
      if hash1.kind_of?(Hash) && hash2.kind_of?(Hash) 
        # Merge hash...
        hash1 ||= {}
        hash2 ||= {}
        ret = {}
        [hash1.keys, hash2.keys].flatten.compact.uniq.each do |key|
          ret[key] = merge_config(hash1[key], hash2[key])
        end
      end
      return ret
    end
      
    ################################################
    ## CONFIG FILE DSL
    
    # Scopes the block contents to the specified mode.  You should pass :all
    # if you want to apply to all modes.
    def mode(mode_name, &block)
      old_mode = @current_mode
      @current_mode = self[("mode(#{mode_name})" || :'mode(all)').to_sym] ||= {}
      yield if block_given?
      @current_mode = old_mode
    end

    def config(domain, opts = {}, &block) 
      yield(opts) if block_given?
      hash = (current_mode["config(#{domain})".to_sym] ||= {})
      hash.merge! symbolize_keys(opts)
      return self
    end
    
    def proxy(path, opts = {}, &block)
      yield(opts) if block_given?
      self["proxy(#{path})".to_sym] = symbolize_keys(opts)
      return self
    end

    def env; Abbot.env || {}; end 
    
    def eval_ruby(content) 
      eval(content)
      return self
    end
    
    def apply_yaml(yaml)
      # iterate through the keys and basically convert them into equivalent
      # ruby calls.
      yaml.each do |key, hash|
        case key
        when /^mode\(.*\)$/:
          self.mode key.gsub(/^mode\((.*)\)$/, '\1').to_sym do 
            self.apply_yaml(hash)
          end
        
        when /^config\(.*\)$/:
          self.config(key.gsub(/^config\((.*)\)$/, '\1').to_sym, hash)
          
        when /^proxy\(.*\)$/:
          self.proxy(key.gsub(/^proxy\((.*)\)$/, '\1').to_sym, hash)
          
        else
          self[key.to_sym] = symbolize_keys(hash)
        end          
      end
      return self
    end

    def current_mode
      @current_mode ||= (self[:'mode(all)'] ||= {})
    end
    
    protected 
    
    def symbolize_keys(hash)
      ret = {}
      hash.each { |k,v| ret[k.to_sym] = v }
      return ret 
    end
    
  end
  
end

