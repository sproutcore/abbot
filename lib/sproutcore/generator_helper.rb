
module SproutCore

  # You can use these methods basically copy the contents of your templates
  # directory into a target location.
  module GeneratorHelper

    def apply_template(m, root_dir)
      m.directory root_dir

      template_directories.each do |d|
        m.directory File.join(root_dir,d)
      end

      template_files.each do |f|
        f_out = File.join(root_dir,f)
        if f =~ /\.rhtml$/
          m.file f, f_out
        else
          m.template f, f_out
        end
      end
    end

    def template_directories
      template_files(true)
    end

    def template_files(directories=false, cur_dir=nil,cur_base=nil)
      if cur_dir.nil?
        cur_dir = File.join(spec.path,'templates')
        cur_base = ''
      end

      ret = []
      Dir.foreach(cur_dir) do |x|
        next if (x == '.' || x == '..' || x == '.svn')
        base = cur_base + x
        dir = File.join(cur_dir,x)

        if File.directory?(dir)
          ret << (cur_base + x) if directories
          ret += template_files(directories, dir, base + "/")
        else
          ret << (cur_base + x) if !directories
        end
      end

      return ret
    end

    def build_client_directories(m, path)
      parts = File.dirname(path).split('/')
      cpath = []
      parts.each do |p|
        cpath << p
        m.directory File.join(cpath)
      end
    end

    # Convert the Ruby version of the class name to a JavaScript version.
    def client_class_name
      class_name.gsub('::','.')
    end

    def client_namespace
      parts = client_class_name.split('.')
      parts.pop
      return parts * '.'
    end

    def controller_class_name
      ret = client_class_name
      ret += 'Controller' unless ret =~ /Controller$/
      ret
    end

    def controller_instance_name
      ret = controller_class_name.split('.')
      ret[ret.size-1] = ret.last.underscore.camelize(:lower)
      return ret * "."
    end

    def view_class_name
      ret = client_class_name
      ret += 'View' unless ret =~ /View$/
      ret
    end

    # This will convert the file_name provided by Rails to one suitable for
    # the client.  i.e. calendar/event => calendar/sub_dir/event
    def client_file_path(sub_dir, ext=nil, to_strip = nil, fp = nil)
      parts = (fp.nil? ? file_path : fp).split('/')

      # Determine the root dir.  Search clients then frameworks.
      loc = @client_location

      # check for clients
      if loc.nil?
        client_path = File.join(destination_root, "clients")
        app_name = parts.first
        loc = "clients" if File.exists?(client_path) && Dir.new(client_path).include?(app_name)
      end

      # check for frameworks
      if loc.nil?
        client_path = File.join(destination_root, "frameworks")
        app_name = parts.first
        loc = "frameworks" if File.exists?(client_path) && Dir.new(client_path).include?(app_name)
      end

      loc = "clients" if loc.nil? # fallback

      path = parts.insert(parts.size-1,sub_dir).unshift(loc) * '/'

      # We want to stop the final part of the name for controllers and views.
      if to_strip && (path =~ /_#{to_strip}$/)
        path = path.slice(0,path.size - (to_strip.size + 1))
      end

      [path,ext].compact * '.'
    end

    # Returns the base class name, which is the first argument or a default.
    def base_class_name(default_base_class_name = 'SC.Object')
      @args.first || default_base_class_name
    end

    ###################
    # Borrowed from Rails NamedBase

    attr_reader   :name, :class_name, :singular_name, :plural_name
    attr_reader   :class_path, :file_path, :class_nesting, :class_nesting_depth
    alias_method  :file_name,  :singular_name

    def assign_names!(name)
      @name = name
      base_name, @class_path, @file_path, @class_nesting, @class_nesting_depth = extract_modules(@name)
      @class_name_without_nesting, @singular_name, @plural_name = inflect_names(base_name)
      if @class_nesting.empty?
        @class_name = @class_name_without_nesting
      else
        @class_name = "#{@class_nesting}::#{@class_name_without_nesting}"
      end
    end

    # Extract modules from filesystem-style or ruby-style path:
    #   good/fun/stuff
    #   Good::Fun::Stuff
    # produce the same results.
    def extract_modules(name)
      modules = name.include?('/') ? name.split('/') : name.split('::')
      name    = modules.pop
      path    = modules.map { |m| m.underscore }
      file_path = (path + [name.underscore]).join('/')
      nesting = modules.map { |m| m.camelize }.join('::')
      [name, path, file_path, nesting, modules.size]
    end

    def inflect_names(name)
      camel  = name.camelize
      under  = camel.underscore
      plural = under.pluralize
      [camel, under, plural]
    end

  end
end

RubiGen::Base.send(:include,SproutCore::GeneratorHelper)
