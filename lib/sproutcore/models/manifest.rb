# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2011 Strobe Inc.
#            and contributors
# ===========================================================================

require 'set'

module SC

  # A Manifest describes all of the files that should be found inside of a
  # single bundle/language.  A Manifest can have global properties assigned to
  # it which will be used by the manifest entries themselves.  This is largly
  # defined by the manifest build tasks.
  #
  class Manifest < HashStruct
    attr_reader :target

    def entries(opts = {})
      opts[:hidden] ? @entries : @entries.visible
    end

    class EntryList < Array
      def visible
        each.reject { |entry| entry.hidden? }
      end
    end

    def initialize(target, opts)
      super(opts)
      @target = target
      @entries = EntryList.new
      @staging_uuid = 0
    end

    def inspect
      opts = variation.dup
      opts[:target] = target[:target_name]
      desc = opts.keys.sort { |a,b| a.to_s <=> b.to_s }.map { |k| [k, opts[k]].join("=") }.join(" ")
      "SC::Manifest(#{desc})"
    end

    # Invoked just before a manifest is built.  If you load a manifest file
    # this method will not be invoked.
    # === Returns
    #  self
    def prepare!
      if !@is_prepared
        @is_prepared = true
        target.prepare!
        if target.buildfile.task_defined? 'manifest:prepare'
          target.buildfile.invoke 'manifest:prepare',
            :manifest => self,
            :target => self.target,
            :config => self.target.config,
            :project => self.target.project
        end
      end
      return self
    end

    def prepared?; @is_prepared || false; end

    # Returns the options that select the current variation.  The current
    # implementation is hardcoded to return the language, but this may be
    # generalized in the future.
    #
    # You can use this method to select the same manifest in other targets.
    #
    # === Examples
    #
    #   other_manifest = other_target.manifest_for(my_manifest.variation)
    #
    def variation
      return { :language => self[:language] }
    end

    # Builds the manifest if it has not been built yet.
    def build!
      prepare!
      if !@is_built
        @is_built = true
        if target.buildfile.task_defined? 'manifest:build'
          target.buildfile.invoke 'manifest:build',
            :manifest => self,
            :target => self.target,
            :config => self.target.config,
            :project => self.target.project
        end

        # Information indicating where the built app can be found. This is useful
        # when manually uploading builds, to ensure we have the newest build.
        if target[:target_type] == :app
          SC.logger.info "Built #{target[:target_name]} to #{target[:build_root]}/#{target[:build_number]}"
        end
      end
      return self
    end

    def built?; @is_built; end

    #
    # Resets this manifest, and all same-variation manifests the target depends on.
    # This is useful when building: it clears the entries and frees up memory so
    # building doesn't take multiple gigabytes.
    #
    def reset!
      return if @is_resetting
      @is_resetting = true

      targets = target.expand_required_targets({ :theme => true }) + [target]
      entries = targets.map do |t|
        t.manifest_for(variation).reset!
      end

      targets = target.modules({ :debug => false, :test => false, :theme => true }).each do |t|
        t.manifest_for(variation).reset!
      end

      reset_entries!

      @is_resetting = false

      return self
    end

    # Resets the manifest entries.  this is called before a build is
    # performed. This will reset only the entries, none of the other props.
    #
    # === Returns
    #   Manifest (self)
    #
    def reset_entries!
      @is_built = false
      self.delete(:entries)
      @entries = EntryList.new
      return self
    end

    # Returns the manifest as a hash that can be serialized to json or yaml
    def to_hash(opts={})
      ret = super()

      if only_keys = opts[:only]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value if only_keys.include?(key)
        end
        ret = filtered
      end

      # Always include entries unless they are explicitly excluded
      ret[:entries] = entries(opts).map { |e| e.to_hash(opts) }

      if except_keys = opts[:except]
        filtered = {}
        ret.each do |key, value|
          filtered[key] = value unless except_keys.include?(key)
        end
        ret = filtered
      end

      # always add target name. needed to reload
      ret[:target_name] = target.target_name
      return ret
    end

    # Loads a hash into the manifest, replacing whatever contents are
    # already here.
    #
    # === Params
    #  hash:: the hash loaded from disk
    #
    # === Returns
    #  Manifest (self)
    #
    def load(hash)
      merge!(hash)
      entry_hashes = self.delete(:entries) || []
      @entries = EntryList.new
      entry_hashes.each do |opts|
        @entries << ManifestEntry.new(self, opts)
      end

      return self
    end

    # Creates a new manifest entry with the passed options.  Will setup extra
    # tracking needed by entry.
    #
    # ==== Params
    #  opts:: the options you want to set on the entry
    #
    # ==== Returns
    #  the new manifest entry
    #
    def add_entry(filename, opts = {})
      opts[:filename] = filename
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!
      return ret
    end

    # Creates a composite entry with the passed filename.  Expects you to
    # a source_entries option.  This automatically hides the source entries
    # unless you pass the :hide_entries => false option.
    def add_composite(filename, opts = {})
      should_hide_entries = opts.delete(:hide_entries)
      should_hide_entries = true if should_hide_entries.nil?

      opts[:filename] = filename
      opts[:source_entries] ||= []
      opts[:composite] = true
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!

      ret[:source_entries].each { |entry| entry.hide! } if should_hide_entries
      return ret
    end

    # Creates an entry with will apply a build task to the source entry. Use
    # this method when you need to apply a build task to an entry to convert
    # it into another format or to perform some kind of incremental build.
    #
    # === Params
    #  entry:: the entry that should be the source of the transform
    #
    # === Options
    # You can assign any options you like and they will be copied onto the
    # new entry.  The following options, however, have special meaning:
    #
    #  :build_task:: name the new build task you use.  otherwise uses copy
    #  :ext:: the new file extension. if you don't override, the build_path
    #    staging_path and filename will all be adjusted to have this ext.
    #  :hide_entry:: the source entry will be hidden unless set to false
    # === Returns
    #   the new ManifestEntry
    #
    def add_transform(entry, opts ={})
      should_hide_entries = opts.delete(:hide_entries) || opts.delete(:hide_entry)
      should_hide_entries = true if should_hide_entries.nil?

      # Clone important properties to new transform...
      opts = HashStruct.new(opts)

      opts[:filename]   ||= entry[:filename]
      opts[:build_path] ||= entry[:build_path]
      opts[:url]        ||= entry[:url]

      # generate a unique staging path.  If the original entry has its
      # staging_path set == to source_root (optimization for build:copy), then
      # first rebase staging path against the staging root.
      if (staging_path = entry[:staging_path]) == entry[:source_path]
        staging_path = File.join(self[:staging_root], entry[:filename])
      end

      opts[:staging_path] ||= unique_staging_path(staging_path)

      # generate a unique cache path from the staging page.  just sub the
      # staging root for the cache root
      opts[:cache_path] ||= unique_cache_path(entry[:cache_path])

      # copy other useful entries
      opts[:source_entry]   = entry
      opts[:source_entries] = [entry]
      opts[:composite]      = true
      opts[:transform]      = true # make .transform? = true

      # Normalize to new extension if provided.  else copy ext from entry...
      if ext = opts[:ext]
        opts[:url] = opts[:url].ext(ext)
        opts[:staging_path] = opts[:staging_path].ext(ext)
        opts[:build_path] = opts[:build_path].ext(ext)
        opts[:filename] = opts[:filename].ext(ext)
      else
        opts[:ext] = entry[:ext]
      end

      # Create new entry and hide old one
      @entries << (ret = ManifestEntry.new(self, opts)).prepare!

      entry.hide! if should_hide_entries

      # done!
      return ret
    end

    # Finds the first visible entry with the specified filename.  You may also
    # pass any number of additional options which will be used to further
    # restrict your search.  If you pass :hidden => true only hidden entries
    # will be returned.  Otherwise, only visible entries will be returned.
    #
    # You may also include the name of the target you would like to search.
    # The target name should be relative to the target you are requesting
    # from.
    #
    # === Examples
    #
    #   entry = manifest.entry_for('javascript.js')
    #     => returns local javascript.js entry
    #
    #   entry = manifest.entry_for('sproutcore:javascript.js')
    #     => returns entry for javascript.js in 'sproutcore' bundle
    #
    #   entry = manifest.entry_for('sproutcore/costello:javascript.js')
    #
    #
    # === Params
    #   filename:: the filename to search
    #
    # === Options
    #   :hidden:: if true, include hidden entries
    #
    # === Returns
    #   the manifest entry
    def entry_for(filename, opts = {})
      target_name, filename = filename.split(':')
      if filename.nil?  # no targetname given...
        manifest = self
        filename = target_name
      else
        if (_manifest_target = target.target_for(target_name)).nil?
          throw "Cannot file target #{target_name} for entry #{filename}"
        end
        manifest = _manifest_target.manifest_for(self.variation)
        manifest.build!
      end

      manifest.entries(opts).find do |entry|
        (entry[:filename] == filename) && entry.has_options?(opts)
      end
    end

    # Attempts to find any entry matching the specified static URL fragment.
    # the fragment you pass may contain only a portion of the url, and it may
    # exclude the file extension if you choose.  The filter will select the
    # entry with the broadest match possible.
    #
    # This is the root search method used by static_url().
    #
    def find_entry(fragment, opts = {}, seen=nil)

      entry_extname = entry_rootname = ret = target_name = nil

      # optionally you can specify an explicit target name
      split_index = fragment.to_s.index(':') # find first index
      unless split_index.nil?
        target_name = '/' + fragment[0..(split_index-1)] if split_index>0
        fragment    = fragment[(split_index+1)..-1] # remove colon
      end

      # find the current manifest
      if target_name
        cur_target = self.target.target_for(target_name) || self.target
        cur_manifest = cur_target.manifest_for(self.variation).build!
      else
        cur_manifest = self
      end

      extname = File.extname(fragment.to_s)
      extname = nil if extname.empty?

      # Add leading slash and remove extension
      rootname = fragment.to_s.sub(/\/?/, '/').sub(/#{extname}$/, '')

      # look on our own target only if target is named
      ret = cur_manifest.entries(opts).find do |entry|
        next unless entry.has_options?(opts)
        next if extname && (entry.extension != extname)

        normalized_rootname = entry.rootname.sub!(/\/?/, '/') # Add leading slash
        normalized_rootname[-rootname.length, rootname.length] == rootname
      end

      return ret if ret

      # if no match was found, search the same manifests in required targets
      seen ||= Set.new
      seen << cur_manifest.target

      cur_manifest.target.expand_required_targets(:theme => true).each do |t|
        next if seen.include?(t) # avoid recursion

        manifest = t.manifest_for(self.variation).build!
        ret = manifest.find_entry(fragment, opts, seen)
        return ret if ret
      end

      nil
    end

    # Finds a unique staging path starting with the root proposed staging
    # path.
    def unique_staging_path(path)
      # paths = entries(:hidden => true).map { |e| e[:staging_path] }
      # while paths.include?(path)
      #   path = path.sub(/(__\$[0-9]+)?(\.\w+)?$/,"__#{next_staging_uuid}\\2")
      # end
      return path
    end

    # Finds a unique cache path starting with the root proposed staging
    # path.
    def unique_cache_path(path)
      # paths = entries(:hidden => true).map { |e| e[:cache_path] }
      # while paths.include?(path)
      #   path = path.sub(/(__\$[0-9]+)?(\.\w+)?$/,"__#{next_staging_uuid}\\2")
      # end
      return path
    end

    protected

    def next_staging_uuid
      @staging_uuid += 1
    end

  end

end
