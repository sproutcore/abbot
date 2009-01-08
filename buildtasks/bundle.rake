require 'digest/md5'

namespace :bundle do

  desc "computes the build number for the bundle.  If you have set the build_number in the config, then that build number will be used.  Otherwise the build number will be computed by combining an SHA1 hash of every file in the bundle and in any required bundles."
  task :compute_build_number do

    # Use the config.build_number, if specified
    build_number = CONFIG.build_number

    # Compute the build number from the framework files, if needed
    if build_number.nil?
      src = BUNDLE.source_root
      digests = Dir.glob(File.join(src, '**', '*.*')).map do |path|
        allowed = !(path =~ /^#{src}\/(apps|clients|frameworks)\//)
        allowed = allowed && File.exists?(path) && !File.directory?(path)
        allowed ? Digest::SHA1.hexdigest(File.read(path)) : '0000'
      end
      build_number = Digest::SHA1.hexdigest(digests.join)
    end

    # Save the build number
    BUNDLE.build_number = build_number
  end
  
end
