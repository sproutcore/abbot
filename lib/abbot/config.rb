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
        
        if !YAML::load(file_contents).instance_of?(Hash)
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

    ################################################
    ## CONFIG FILE DSL
    
    def config(domain, opts = {}, &block) 
      yield(opts) if block_given?
      self["config(#{domain})".to_sym] = symbolize_keys(opts)
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
      yaml.each { |k, v| self[k.to_sym] = symbolize_keys(v) }
      return self
    end
    
    protected 
    
    def symbolize_keys(hash)
      ret = {}
      hash.each { |k,v| ret[k.to_sym] = v }
      return ret 
    end
    
  end
  
end

