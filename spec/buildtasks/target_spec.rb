require "spec_helper"

describe "namespace :target" do

  include SC::SpecHelpers

  # Invoked when a new target is created to fill in some standard values
  describe "target:prepare" do

    before do
      @project = fixture_project :real_world
      @target = @project.target_for :sproutcore
      @buildfile = @target.buildfile
    end

    def run_task
      @buildfile.invoke 'target:prepare',
        :target => @target, :project => @project, :config => @target.config
    end

    ### loadable -- if true, the target should have index.html and other files
    ###   generated to make it loadable in the browser.
    it "sets target.loadable? if target_type == :app" do
      @target.target_type = :app
      run_task
      @target.should be_loadable
    end

    ### URL_ROOT -- used to compute the url for static assets
    it "uses config.url_root if present" do
      @target.config.url_root = 'foo'
      run_task
      @target.url_root.should eql('foo')
    end

    it "computes url_root => /url_prefix/target_name" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix.should eql('static') # precondition
      run_task
      @target.url_root.should eql("/static/sproutcore")
    end

    it "should collapse an empty url_prefix" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = ''

      run_task
      @target.url_root.should eql("/sproutcore")
    end

    it "should collapse a nil url_prefix" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = nil

      run_task
      @target.url_root.should eql("/sproutcore")
    end

    it "should collapse a starting /" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = '/foo'

      run_task
      @target.url_root.should eql('/foo/sproutcore')
    end

    it "should not add / if prefix begins with http://" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = "http://foo.com/blah"

      run_task
      @target.url_root.should eql('http://foo.com/blah/sproutcore')
    end

    it "should not add / if prefix begins with https://" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = "https://foo.com/blah"

      run_task
      @target.url_root.should eql('https://foo.com/blah/sproutcore')
    end

    it "should not add / if prefix begins with foobar://" do
      @target.config.url_root.should be_nil # precondition
      @target.config.url_prefix = "foobar://foo.com/blah"

      run_task
      @target.url_root.should eql('foobar://foo.com/blah/sproutcore')
    end

    ### INDEX_ROOT -- used to compute the URLs used to access index files
    it "uses config.index_root if present" do
      @target.config.index_root = 'foo'
      run_task
      @target.index_root.should eql('foo')
    end

    it "computes index_root => /index_prefix/target_name" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = 'static'
      run_task
      @target.index_root.should eql("/static/sproutcore")
    end

    it "should collapse an empty index_prefix" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = ''

      run_task
      @target.index_root.should eql("/sproutcore")
    end

    it "should collapse an nil index_prefix" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = nil

      run_task
      @target.index_root.should eql("/sproutcore")
    end

    it "should not add / if prefix begins with http://" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = "http://foo.com/blah"

      run_task
      @target.index_root.should eql('http://foo.com/blah/sproutcore')
    end

    it "should not add / if prefix begins with https://" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = "https://foo.com/blah"

      run_task
      @target.index_root.should eql('https://foo.com/blah/sproutcore')
    end

    it "should not add / if prefix begins with foobar://" do
      @target.config.index_root.should be_nil # precondition
      @target.config.index_prefix = "foobar://foo.com/blah"

      run_task
      @target.index_root.should eql('foobar://foo.com/blah/sproutcore')
    end


    ### BUILD_ROOT -- Used to compute the root location for building files
    it "uses config.build_root if present, expanded" do
      @target.config.build_root = 'foo'
      run_task
      @target.build_root.should eql(File.expand_path('foo'))
    end

    it "computes build_root => /project_root/build_prefix/url_prefix/target_name, expanded" do
      @target.config.build_root.should be_nil # precondition
      @target.config.url_prefix = 'static'
      @target.config.build_prefix = 'tmp/foo'
      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp foo static sproutcore)))
      @target.build_root.should eql(expected)
    end

    it "should collapse an empty build_prefix" do
      @target.config.url_prefix = 'static'
      @target.config.build_prefix = ''

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(static sproutcore)))
      @target.build_root.should eql(expected)
    end

    it "should collapse an nil build_prefix" do
      @target.config.url_prefix = 'static'
      @target.config.build_prefix = nil

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(static sproutcore)))
      @target.build_root.should eql(expected)
    end

    it "should collapse an empty url_prefix" do
      @target.config.url_prefix = ''
      @target.config.build_prefix = 'tmp/build'

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp build sproutcore)))
      @target.build_root.should eql(expected)
    end

    it "should collapse an nil url_prefix" do
      @target.config.url_prefix = nil
      @target.config.build_prefix = 'tmp/build'

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp build sproutcore)))
      @target.build_root.should eql(expected)
    end

    ### STAGING_ROOT -- Used to compute the root location for staging
    it "uses config.staging_root if present, expanded" do
      @target.config.staging_root = 'foo'
      run_task
      @target.staging_root.should eql(File.expand_path('foo'))
    end

    it "computes staging_root => /project_root/staging_prefix/url_prefix/target_name, expanded" do
      @target.config.staging_root.should be_nil # precondition
      @target.config.url_prefix = 'static'
      @target.config.staging_prefix = 'tmp/foo'
      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp foo static sproutcore)))
      @target.staging_root.should eql(expected)
    end

    it "should collapse an empty staging_prefix" do
      @target.config.url_prefix = 'static'
      @target.config.staging_prefix = ''

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(static sproutcore)))
      @target.staging_root.should eql(expected)
    end

    it "should collapse an nil staging_prefix" do
      @target.config.url_prefix = 'static'
      @target.config.staging_prefix = nil

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(static sproutcore)))
      @target.staging_root.should eql(expected)
    end

    it "should collapse an empty url_prefix" do
      @target.config.url_prefix = ''
      @target.config.staging_prefix = 'tmp/build'

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp build sproutcore)))
      @target.staging_root.should eql(expected)
    end

    it "should collapse an nil url_prefix" do
      @target.config.url_prefix = nil
      @target.config.staging_prefix = 'tmp/build'

      run_task

      expected = File.expand_path(File.join(@project.project_root, %w(tmp build sproutcore)))
      @target.staging_root.should eql(expected)
    end

    ### BUILD_NUMBER - the build number

    it "should compute a build number for the target" do
      @target.build_number.should be_nil #precondition
      run_task
      @target.build_number.should_not be_nil
    end

  end

end
