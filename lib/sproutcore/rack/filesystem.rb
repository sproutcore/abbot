# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Mike Subelsky
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

require 'rubygems'
require 'rack'
require 'rack/request'
require 'rack/utils'
require 'rack/file'

module SC
  module Rack
    
    # Sends and modifies files in the local file system. Uses Rack::Rack::File to 
    # transfer the file, which makes this work with rack/sendfile and other 
    # middleware. Some code originally adapted from Rack::Rack::File.
    class Filesystem
      
      def initialize(project)
        @project = project
      end
      
      def root_dir
        unless @root_dir
          @root_dir = @project.project_root
        end
        return @root_dir
      end
      
      # Accepts the following commands
      #
      # GET /foo/bar/blah
      # - send blah back to the client
      # 
      # POST /foo/bar/blah with no "action" body parameter
      # - also sends contents of blah back to the client (defeats caching)
      # 
      # POST to /foo/bar/blah with "action=save" and "file" body parameters
      # - create a file named "blah" with contents  of file  OR overwrite 
      #   "blah" with contents of file; create /foo/bar if needed
      # 
      # POST to /foo/bar/blah with "action=touch" body parameter
      # - create an empty file named "blah" OR update the timestamp of blah; 
      #   create /foo/bar if needed
      # 
      # POST to /foo/bar/blah with "action=makedir" body parameter
      # - create a directory named "blah" and create parent directories if 
      #   needed
      # 
      # POST to /foo/bar/blah with "action=append" and "file" body parameters
      # - append the contents of the file body parameter to the blah file; 
      #   return error if "blah" doesn't exist
      # 
      # POST to /foo/bar/blah with "action=remove" body parameter
      # - delete a file or directory named "blah"; will fail if directory is 
      #   not empty
      def call(env)
        regex = /^\/sproutcore\/fs/
        params = ::Rack::Request.new(env).params
        
        path = env["PATH_INFO"]
        return [404, {}, "not found"] unless path =~ regex
        
        path = path.sub regex, '' # remove path prefix
        action = params['action']
        
        case action
        when nil
          send_file(path)
        when 'save'
          save_file(path,params)
        when 'append'
          append_file(path,params)
        when 'touch'
          touch_file(path)
        when 'makedir'
          make_directory(path)
        when 'remove'
          remove_path(path)
        else
          forbidden("Unknown action #{params['action']}")
        end
      rescue StandardError
        return forbidden("Cannot #{action} #{path} due to #{$!.message}")
      end
      
      private
      
      def send_file(original_path)
        with_sanitized_path(original_path) do |sanitized_path|
          with_readable_path(sanitized_path) do |readable_path|
            send_file_response(readable_path)
          end
        end
      end
      
      def save_file(original_path,params)
        with_sanitized_path(original_path) do |sanitized_path|
          with_modifiable_path(sanitized_path) do |dest_path|
            save_to_file(dest_path,params)
            success("Saved #{dest_path}")
          end
        end
      end
      
      def append_file(original_path,params)
        with_sanitized_path(original_path) do |sanitized_path|
          with_modifiable_path(sanitized_path) do |dest_path|
            append_to_file(dest_path,params)
            success("Appended to #{dest_path}")
          end
        end
      end
      
      def touch_file(original_path)
        with_sanitized_path(original_path) do |sanitized_path|
          with_modifiable_path(sanitized_path) do |dest_path|
            FileUtils.touch(dest_path)
            success("Touched #{original_path}")
          end
        end
      end
      
      def make_directory(original_path)
        with_sanitized_path(original_path) do |sanitized_path|
          with_modifiable_path(sanitized_path) do |dest_path|
            FileUtils.mkdir(dest_path)
              # with_modifiable_path call takes care of any parent directories
            success("Created directory #{original_path}")
          end
        end
      end
      
      # will raise SystemCallError if the path to be removed is a non-empty 
      # directory
      
      def remove_path(original_path)
        with_sanitized_path(original_path) do |destroy_path|
          return not_found(original_path) unless File.exist?(destroy_path)
          return forbidden(
            "Cannot modify #{destroy_path}"
          ) unless File.writable?(destroy_path)
          if File.directory?(destroy_path)
            Dir.rmdir(destroy_path)
            success("Removed directory #{destroy_path}")
          else
            File.delete(destroy_path)
            success("Removed file #{destroy_path}")
          end
        end
      end
      
      def save_to_file(dest_path,params)
        with_tempfile_path(params['file']) do |tempfile_path|
          puts "moving #{tempfile_path} to #{dest_path}"
          FileUtils.mv(tempfile_path,dest_path)
        end
      end
      
      def append_to_file(dest_path,params)
        with_tempfile_path(params['file']) do |tempfile_path|
          ::Rack::File.open(dest_path,'a') do |dest_file|
            ::Rack::File.open(tempfile_path,'r') do |source_file|
              FileUtils.copy_stream(source_file,dest_file)
            end
          end
        end
      end
      
      def with_tempfile_path(file_param)
        return forbidden("Did not receive a file") unless file_param
        tempfile = file_param[:tempfile]
        return forbidden("File was not uploaded") unless tempfile
        yield tempfile.path
      end
      
      def send_file_response(path)
        if size = File.size?(path)
          # use Rack::File so streaming works and for max compatibility with 
          # other handlers
          # TODO we could make this work with Rack::Sendfile pretty easily if 
          # the server supports it
          body = ::Rack::File::new(root_dir)
          body.path = path
          body
        else
          # file does not provide size info via stat, so we have to read it 
          # into memory
          body = [File.read(path)]
          size = ::Rack::Utils.bytesize(body.first)
        end
        
        [200, {
          "Last-Modified"  => File.mtime(path).httpdate,
          "Content-Type" =>
            ::Rack::Mime.mime_type(File.extname(path), 'text/plain'),
          "Content-Length" => size.to_s
        }, body]
      end
      
      def with_readable_path(path)
        return not_found(path) unless File.file?(path)
        return forbidden("Cannot read #{path}") unless File.readable?(path)
        yield path
      end
      
      def with_sanitized_path(orig_path)
        path = ::Rack::Utils.unescape(orig_path)
        return forbidden("Illegal path #{path}") if path.include?("..")
        
        yield File.join(root_dir, path)
      end
      
      def not_found(path)
        body = "Path not found: #{path}\n"
        [404, {
          "Content-Type" => "text/plain",
          "Content-Length" => body.size.to_s},
          [body]
        ]
      end
      
      def forbidden(body)
        body += "\n" unless body =~ /\n$/
        [403, {
          "Content-Type" => "text/plain",
          "Content-Length" => body.size.to_s},
          [body]
        ]
      end
      
      def success(msg)
        [ 200, { 'Content-Type' => 'text/html' }, msg ]
      end
      
      def with_modifiable_path(path)      
        # can't use File.dirname here as it only recognizes Unix separators
        path_parts = path.split(::Rack::File::SEPARATOR)
        dir_name = File.join(path_parts[0..-2])
        
        begin
          FileUtils.mkdir_p(dir_name)
        rescue Errno::EACCES
          return forbidden(
            "Cannot create directory #{dir_name} due to #{$!.message}"
          )
        end
        
        return forbidden(
          "Cannot write to directory #{dir_name}"
        ) unless File.writable?(dir_name)
        
        if File.file?(path) && !File.writable?(path)
          return forbidden("Cannot write to file #{path}")
        end
        
        yield path
      end
      
    end
  end
end
