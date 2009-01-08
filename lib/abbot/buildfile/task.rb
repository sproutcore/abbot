module Abbot
  
  # Buildfile tasks are rake tasks with a few extras added to support 
  # unique buildfile constraints.
  #
  class Buildfile::Task < ::Rake::Task
    include ::Rake::Cloneable

    IGNORE = %w(@lock @application @already_invoked)

    def dup(app=nil)
      app = application if app.nil?
      sibling = self.class.new(name, app)
      self.instance_variables.each do |key|
        next if IGNORE.include?(key)
        sibling.instance_variable_set(key, self.instance_variable_get(key))
      end
      sibling.taint if tainted?
      sibling
    end
    
    # returns true if the task has already been invoked since the last time
    # it was reset
    def invoked?; @already_invoked || false; end
    
  end

end

    