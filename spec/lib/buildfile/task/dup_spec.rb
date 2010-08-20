require "spec_helper"

# define a custom subclass of the task to make sure classes are copied
class CustomTestTask < SC::Buildfile::Task
  attr_accessor :test_property
end

describe SC::Buildfile::Task, 'dup' do

  before do
    @app = SC::Buildfile.define # used to hook a buildtask
    @task = SC::Buildfile::Task.new(:foo, @app)
  end

  it "should clone actions and prerequisites" do
    @app.define! do
      task :bar => :foo do
        :test_action
      end
    end
    @task = @app.lookup :bar
    @task.actions.size.should eql(1) # check precondition
    @task.prerequisites.size.should eql(1) # check precondition

    action = @task.actions.first
    pre = @task.prerequisites.first

    task2 = @task.dup
    task2.actions.size.should eql(1)
    task2.actions.first.should eql(action)

    task2.prerequisites.size.should eql(1)
    task2.prerequisites.first.should eql(pre)

  end

  it "should take passed application property if defined" do
    app2 = SC::Buildfile.define
    task2 = @task.dup(app2)
    task2.application.should eql(app2)
  end

  it "should clone application property is not defined" do
    @task.dup.application.should eql(@app)
  end

  it "should duplicate any ivars from subclasses" do
    @task = CustomTestTask.new :foo, @app
    @task.test_property = :bar

    task2 = @task.dup
    task2.test_property.should eql(:bar)
  end

end
