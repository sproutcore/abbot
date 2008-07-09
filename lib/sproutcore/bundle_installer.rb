require 'pathname'

module SproutCore

  # An installer can install, update or remove frameworks and clients in a
  # project.  You generally will not work with an installer instance directly
  # but instead call the install methods on the SC.library which will 
  # instantiate an installer class for you.
  class BundleInstaller

    attr  :library 
    attr  :target
    
    def self.configure_tool_options(opts, options = {})
      
      can_install = options[:can_install].nil? ? true : options[:can_install]

      ### General Options
      
      opts.on("-d", "--dry-run", "Logs the expected behavior of this utility without actually changing anything.") do |opt_dry_run|
        options[:dry_run] = opt_dry_run
      end
      
      opts.on("-v", "--[no-]verbose", "If set, extra debug output will be displayed during the build") do |opt_verbose|
        options[:verbose] = !!opt_verbose
      end

      opts.on("-l", "--library=PATH", "Normally sc-install works within the library of your working directory.  You can name an arbitrary location for the library with this option instead.") do |opt_library|
        options[:library_root] = opt_library
      end

      opts.on("-t", "--target=PATH", "Set the install path for the bundle.  This can be either a bundle name or an absolute path.") do |opt_target|
        options[:target] = opt_target
      end
      
      ### Install Only Options
      
      if can_install
        opts.on("-s", "--source=URL", "Specify a URL to install from.  You can provide either a full URL or just the path on github to your project.  The tool assumes that the url you provide plus '.git' can be used to clone the project.")

        opts.on("-f", "--[no-]force", "Normally SproutCore will not install a bundle if a directory already exists at the install location.  If you include this option, it will forceably install bundles even if it has to delete an existing directory.") do |opt_force|
          options[:force] = !!opt_force
        end
      end
      
    end
    
    # ==== Options
    # :library :: the owner library.  Required.
    # :target  :: the target output directory. Defaults to :frameworks 
    #
    def initialize(opts = {})
      @library = opts[:library]
      @target = opts[:target] || :frameworks
    end
    
    # ==== Returns
    # The install directory as currently configured.  Requires library and
    # target.
    def install_root
      raise "BundleInstaller cannot be used without a library" if library.nil?
      File.join(library.root_path, target.to_s)
    end

    # Attempts to install the named bundle using any passed options.  If a 
    # directory already exists at the install path location, then this method
    # will attempt to update the bundle there rather than install it.
    #
    def install(bundle_name, opts ={})

      # Calculate the install path.  If a directory already exists at the
      # location, try an update instead.
      install_path = normalize_install_path(bundle_name, opts)
      if !opts[:skip_check] && File.exists?(install_path)
        if opts[:force]
          remove(bundle_name, opts)
          opts.delete(:force)
          opts[:skip_check] = true if opts[:dry_run]
          install(bundle_name, opts)
        else
          display_path = display_path_for(install_path)
          SC.logger.warn %(#{bundle_name} appears to be installed already!)
          SC.logger.info %( ~ If you do not think this bundle is properly installed remove the directory at:)
          SC.logger.info %( ~ #{install_path})
          SC.logger.info %( ~ and try again.)
        end
        
      # Directory does not exist at install location, fetch the resource...
      else
        # Compute/normalize the github path
        github_path = normalize_github_path(bundle_name, opts) 
        SC.logger.info("Installing #{bundle_name}...")
        self.fetch(github_path, install_path, opts)
      end
      
    end
    
    # Attempts to update the named bundle to the latest revision using any
    # passed options.  If the directory does not contain a git repository,
    # and the :force option is set, then this tool will delete the file at the 
    # specified location and re-install it.
    def update(bundle_name, opts = {})
      install_path = normalize_install_path(bundle_name, opts) 
      display_path = display_path_for(install_path)
      git_path = File.join(install_path, '.git')

      if (!File.exists?(install_path))
        SC.logger.info(" ~ #{bundle_name} is not installed.")
        self.install(bundle_name, opts)

      elsif File.exists?(git_path)
        SC.logger.info("Updating #{bundle_name} at #{display_path}...")
        if !has_git?
          SC.logger.warn(" ~ git it not installed!")
          raise "Cannot update because git is installed"
        else
          SC.logger.debug(" ~ cd #{install_path};")
          SC.logger.debug(" ~ git pull")
          if !opts[:dry_run]
            `cd #{install_path}; git pull`
          end
        end
        
      elsif opts[:force]
        SC.logger.info("Updating #{bundle_name} at #{display_path}...")
        SC.logger.warn(" ~ Installed bundle was not installed using git.  Removing and reinstalling instead.")
        remove(bundle_name, opts)
        install(bundle_name, opts)
      
      else
        
        SC.logger.info("Updating #{bundle_name} at #{display_path}...")
        SC.logger.fatal(" ~ Something is already installed at #{display_path} that cannot be updated!")
        SC.logger.fatal(" ~ Try the --force option to remove and reinstall instead.")
      end
        
    end

    # Attemps to remove the bundle installed at the specified location.
    def remove(bundle_name, opts = {})
      install_path = normalize_install_path(bundle_name, opts)
      display_path = display_path_for(install_path)
      if File.exists?(install_path)
        SC.logger.info("Removing #{bundle_name} at #{install_path}") 
        SC.logger.debug(" ~ rm_rf #{install_path}")
        if !opts[:dry_run]
          FileUtils.rm_rf(install_path)
        end
      else
        SC.logger.warn("Bundle #{bundle_name} is not installed at #{display_path}.")
        SC.logger.info(" ~ You can specify an alternate location using the --target option.")
      end
    end

    # Tries to fetch the specified github_path to the named location.  If the
    # fetched path uses tar/zip, then the file will be decompressed into that
    # location.
    # 
    # ==== Options
    # :method :: Indicates the preferred fetch form.  Can be git, zip, or tar
    def fetch(github_path, install_path, opts)  
      SC.logger.info(" ~ Fetching from #{github_path}")
      method = opts[:method] || (has_git? ? :git : has_zip? ? :zip : :tar)
      
      SC.logger.debug(" ~ using method: #{method}")
      
      if (method == :git) && has_git? 
        install_dir = File.dirname(install_path)
        install_filename = File.basename(install_path)
        SC.logger.debug %( ~ cd #{install_dir};)
        SC.logger.debug %( ~ git clone #{github_path}.git "#{install_filename}")
        
        if !opts[:dry_run]
          result = `cd #{install_dir}; git clone #{github_path}.git "#{install_filename}"`
        end
        
      elsif (method == :zip) && has_zip?
        raise "ZIP not yet supported!"
        
      elsif (method == :tar) && has_tar?
        raise "TAR not yet supported!"
        
      # If none of the fetch mechanisms are installed, ask the user to 
      # install git.
      else
        SC.logger.info(" ~ Cannot fetch because git is not installed")
        SC.logger.info(" ~ Please install git and try again.")
        raise "No fetch tool installed"
      end
    end
    
    # ==== Returns
    # true if zip appears to be installed.
    def has_zip?; @has_zip = has_tool?('zip -v', @has_zip); end

    # ==== Returns
    # true if git appears to be installed
    def has_git?; @has_git = has_tool?('git --version', @has_git); end
    
    # ==== Returns
    # true if tar appears to be installed
    def has_tar?; @has_tar = has_tool?('tar --usage', @has_tar); end

    protected
    
    def normalize_github_path(bundle_name, opts ={})
      github_path = opts[:source]

      # If a path was given, try to clean it up...
      if github_path
        # if http, then everything is cool...
        if !(github_path =~ /^http/)
          # append / if needed... 
          github_path = "/#{github_path}" unless github_path =~ /^\//
          # prepend hostname
          github_path = "http://github.com#{github_path}"
        end
        
      else
        bundle_string = bundle_name.to_s.downcase.gsub(" ",'-')
        
        # sproutcore and prototype are special cases...
        if bundle_name == 'sproutcore'
          github_path = '/sproutit/sproutcore'

        elsif ['prototype', 'jquery'].include?(bundle_string)
          github_path = "/sproutit/sproutcore-#{bundle_string}"
          
        # Typical bundle name like okito-plotkit ->
        # /okito/sproutcore-plotkit.git
        else
          github_account, github_project = bundle_string.split('-')
          if github_project.nil?
            github_project = github_account
            github_account = 'sproutit'
          end
          github_path = "/#{github_account}/sproutcore-#{github_project}"
        end
        
        # Add hostname
        github_path = "http://github.com#{github_path}"
      end
      
      return github_path
    end
    
    # Computes the normalized install path for the bundle.
    def normalize_install_path(bundle_name, opts = {})
      install_name = opts[:target] || bundle_name.to_s.downcase
      is_absolute = Pathname.new(install_name).absolute?
      
      # Add install_root unless pathname is absolute
      is_absolute ? install_name : File.expand_path(File.join(install_root, install_name))
    end
    
    def display_path_for(install_path)
      install_path.gsub(/^#{library.root_path}\/?/,'')
    end
    
    def has_tool?(tool_name, cached_result)
      return cached_result unless cached_result.nil?
      test_exec = `#{tool_name}` rescue nil
      return !test_exec.nil? && test_exec.size > 0
    end
    
  end
  
end