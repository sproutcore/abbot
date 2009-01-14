require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe "namespace :manifest" do
  
  include SC::SpecHelpers
  
  before do
    @project = fixture_project :real_world
    @target = @project.target_for :sproutcore
    @buildfile = @target.buildfile
    @manifest = @target.manifest_for(:language => :en)
    
    @target.prepare! # make sure its ready for the manifest...
  end

  def run_task(task_name)
    @buildfile.execute_task task_name,
      :manifest => @manifest,
      :target =>   @target, 
      :project =>  @project, 
      :config =>   @target.config
  end

  # Prepares some standard properties needed by the manifest
  describe "manifest:prepare" do
    
    def run_task; super('manifest:prepare'); end
    
    it "sets build_root => target.build_root/language/build_number" do
      run_task
      expected = File.join(@target.build_root, 'en', @target.build_number)
      @manifest.build_root.should == expected
    end
    
    it "sets staging_root => staging_root/language/build_number" do
      run_task
      expected = File.join(@target.staging_root, 'en', @target.build_number)
      @manifest.staging_root.should == expected
    end

    it "sets url_root => url_root/language/build_number" do
      run_task
      expected = [@target.url_root, 'en', @target.build_number] * '/'
      @manifest.url_root.should == expected
    end

    it "sets source_root => target.source_root" do
      run_task
      @manifest.source_root.should == @target.source_root
    end
    
    it "sets index_root => index_root/language/build_number" do
      run_task
      expected = [@target.index_root, 'en', @target.build_number] * '/'
      @manifest.index_root.should == expected
    end
    
  end
  
  # Adds a copyfile entry for each item in the source
  describe 'manifest:catalog' do
    
    def run_task
      @manifest.prepare! # this should be run first...
      super('manifest:catalog')
    end
    
    it "create an entry for each item in the target regardless of language with the relative path as filename" do
      run_task
      
      # collect filenames from target dir...
      filenames = Dir.glob(File.join(@target.source_root, '**','*'))
      filenames.reject! { |f| File.directory?(f) }
      filenames.map! { |f| f.sub(@target.source_root + '/', '') }
      filenames.reject! { |f| f =~ /^(apps|frameworks)/ }
            
      entries = @manifest.entries.dup # get entries to test...
      filenames.each do |filename|
        entry = entries.find { |e| e.filename == filename }
        if entry.nil?
          nil.should == filename # oops!  not found...
        else
          entry.filename.should == filename
          entry.build_task.should == 'build:copy'
          entry.build_path.should == File.join(@manifest.build_root, filename)
          entry.staging_path.should == File.join(@manifest.source_root, filename)
          entry.source_path.should == entry.staging_path
          entry.url.should == [@manifest.url_root, filename] * '/'
          entry.hidden?.should be_false
        end
          
        (entry.nil? ? nil : entry.filename).should == filename
        entries.delete entry
      end
      entries.size.should == 0
    end
    
  end
  
  describe "manifest:hide_buildfiles" do
    
    def run_task
      @manifest.prepare!
      super('manifest:hide_buildfiles')
    end
    
    it "should hide any Buildfile, sc-config, or sc-config.rb" do
      run_task
      @manifest.entry_for('Buildfile', :hidden => true).hidden?.should be_true
    end
    
    it "should hide any non .js file outside of .lproj dirs" do
      run_task
      @manifest.entry_for('README', :hidden => true).hidden?.should be_true
      @manifest.entry_for('lib/index.html', :hidden => true).hidden?.should be_true
    end
    
    it "should NOT hide non-js files inslide lproj dirs" do
      run_task
      entry = @manifest.entry_for('english.lproj/demo.html', :hidden => true)
      entry.hidden?.should be_false
    end
    
  end

end
