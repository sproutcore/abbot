#
# The Chance factory.
# All methods require two parts: a key and a hash of options. The hash will be used in
# the case of a cache missed.
#
module Chance
  module ChanceFactory
    
    @instances = {}
    @file_hashes = {}
    class << self
      def clear_instances
        @file_hashes = {}
        @instances = {}
      end
    
      def instance_for_key(key, opts)
        if not @instances.include? key
          @instances[key] = Chance::Instance.new(opts)
        end
        
        return @instances[key]
      end
    
      # Call with a hash mapping instance paths to absolute paths. This will compare with
      # the last 
      def update_instance(key, opts, files)
        instance = instance_for_key(key, opts)
        last_hash = @file_hashes[key] || {}
        
        # If they are not equal, we might as well throw everything. The biggest cost is from
        # Chance re-running, and it will have to anyway.
        if not last_hash.eql? files
          instance.unmap_all
          files.each {|path, identifier|
            instance.map_file path, identifier
          }
          
          @file_hashes[key] = files
        end
      end
      
    end
  end
end