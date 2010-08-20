require "spec_helper"

require 'tempfile'

# Add dummy task we can use to test general option processing
class SC::Tools
  desc "dummy", "a dummy task"
  def dummy; end
end

describe SC::Tools do

  include SC::SpecHelpers

  describe "logger options" do

    before do
      save_env
    end

    after do
      restore_env
    end

    it "should default to warn log level" do
      SC::Tools.start %w(dummy)
      SC.env.log_level.should == :warn
    end

    it "should set log level to :info on --verbose" do
      SC::Tools.start %w(dummy --verbose)
      SC.env.log_level.should == :info
    end

    it "should set log level to :info on -v" do
      SC::Tools.start %w(dummy -v)
      SC.env.log_level.should == :info
    end

    it "should set log level to :debug on --very-verbose" do
      SC::Tools.start %w(dummy --very-verbose)
      SC.env.log_level.should == :debug
    end

    it "should set log level to :debug on -V" do
      SC::Tools.start %w(dummy -V)
      SC.env.log_level.should == :debug
    end

    it "takes -V in preference to -v" do
      SC::Tools.start %w(dummy -vV)
      SC.env.log_level.should == :debug
    end

    it "takes --logfile option to specify output" do
      tmpfile = Tempfile.new('foo')
      SC::Tools.start %(dummy --logfile=#{tmpfile.path}).split(' ')
      SC.env.logfile.should eql(tmpfile.path)
      tmpfile.close
    end

  end

  describe "build mode options" do

    before do
      save_env
    end

    after do
      restore_env
    end

    it "should default to :production build mode" do
      SC::Tools.start %w(dummy)
      SC.build_mode.should eql(:production)
    end

    it "should accept --mode=foo option" do
      SC::Tools.start %w(dummy --mode=foo)
      SC.build_mode.should eql(:foo)
    end

    it "should accept deprecated --environment=foo option" do
      SC::Tools.start %w(dummy --environment=foo)
      SC.build_mode.should eql(:foo)
    end

    it "should always downcase mode name" do
      SC::Tools.start %w(dummy --mode=FOO)
      SC.build_mode.should eql(:foo)
    end

  end

end
