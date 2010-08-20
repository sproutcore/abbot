# ===========================================================================
# Project:   Abbot - SproutCore Build Tools
# Copyright: ©2009 Apple Inc.
#            portions copyright @2006-2009 Sprout Systems, Inc.
#            and contributors
# ===========================================================================

module SC

  # Buildfile tasks are rake tasks with a few extras added to support
  # unique buildfile constraints.  Much of this source code is borrowed from
  # Rake 0.8.3
  #
  class Buildfile::Task
    include Cloneable

    # List of prerequisites for a task.
    attr_reader :prerequisites

    # List of actions attached to a task.
    attr_reader :actions

    # Application owning this task.
    attr_accessor :application

    # Comment for this task.  Restricted to a single line of no more than 50
    # characters.
    attr_reader :comment

    # Full text of the (possibly multi-line) comment.
    attr_reader :full_comment

    # Array of nested namespaces names used for task lookup by this task.
    attr_reader :scope

    # The number of times this task has been invoked.  Use to ensure that
    # the task was invoked during some call chain...
    attr_reader :invoke_count

    # The number of times the task was actually executed.  This may differ
    # from the invoke_count if the task was invoked but was not needed.
    attr_reader :execute_count

    # Various options you can set on the task to control log level, etc.
    attr_reader :task_options

    # Return task name
    def to_s
      name
    end

    def inspect
      "<#{self.class} #{name} => [#{prerequisites.join(', ')}]>"
    end

    # List of sources for task.
    attr_writer :sources
    def sources
      @sources ||= []
    end

    # First source from a rule (nil if no sources)
    def source
      @sources.first if defined?(@sources)
    end

    IGNORE = %w(@lock @application)
    def dup(app=nil)
      app = application if app.nil?
      sibling = self.class.new(name, app)
      self.instance_variables.each do |key|
        next if IGNORE.include?(key.to_s) # instance_variables is an array of symbols in Ruby 1.9
        sibling.instance_variable_set(key, self.instance_variable_get(key))
      end
      sibling.taint if tainted?
      sibling
    end

    # Create a task named +task_name+ with no actions or prerequisites. Use
    # +enhance+ to add actions and prerequisites.
    def initialize(task_name, app)
      @name = task_name.to_s
      @prerequisites = []
      @actions = []
      @full_comment = nil
      @comment = nil
      @lock = Monitor.new
      @application = app
      @scope = app.current_scope
      @arg_names = nil
      @invoke_count = @execute_count = 0
      @task_options = {}
    end

    # Enhance a task with prerequisites or actions.  Returns self.
    def enhance(deps=nil, &block)
      @prerequisites |= deps if deps
      @actions << block if block_given?
      self
    end

    # Name of the task, including any namespace qualifiers.
    def name
      @name.to_s
    end

    # Name of task with argument list description.
    def name_with_args # :nodoc:
      if arg_description
        "#{name}#{arg_description}"
      else
        name
      end
    end

    # Argument description (nil if none).
    def arg_description # :nodoc:
      @arg_names ? "[#{(arg_names || []).join(',')}]" : nil
    end

    # Name of arguments for this task.
    def arg_names
      @arg_names || []
    end

    # Clear the existing prerequisites and actions of a rake task.
    def clear
      clear_prerequisites
      clear_actions
      self
    end

    # Clear the existing prerequisites of a rake task.
    def clear_prerequisites
      prerequisites.clear
      self
    end

    # Clear the existing actions on a rake task.
    def clear_actions
      actions.clear
      self
    end

    # Invoke the task if it is needed.  Prerequites are invoked first.
    def invoke(*args)
      task_args = TaskArguments.new(arg_names, args)
      invoke_with_call_chain(task_args, InvocationChain::EMPTY)
    end

    def self.log_indent
      @task_indent ||= ''
    end

    def self.indent_logs
      @task_indent = (@task_indent || '') + '  '
    end

    def self.outdent_logs
      @task_indent = (@task_indent || '')[0..-3]
    end

    # Same as invoke, but explicitly pass a call chain to detect
    # circular dependencies.
    def invoke_with_call_chain(task_args, invocation_chain) # :nodoc:
      unless invocation_chain.already_invoked?(self)
        invocation_chain = InvocationChain.append(self, invocation_chain)
        @lock.synchronize do

          indent = self.class.indent_logs

          # Use logging options to decide what to output
          # one of :env, :name, :none
          log_opt = task_options[:log] || :none
          if [:name, :env].include?(log_opt)
            SC.logger.debug "#{indent}invoke ~ #{name} #{format_trace_flags}"
          end

          if log_opt == :env
            TASK_ENV.each do |key, value|
              next if %w(config task_env).include?(key.to_s.downcase)
              SC.logger.debug "#{indent}  #{key} = #{value.inspect}"
            end
          end

          t_start = Time.now.to_f * 1000

          invocation_chain = invoke_prerequisites(task_args, invocation_chain)
          @invoke_count += 1
          execute(task_args) if needed?

          t_end = Time.now.to_f * 1000
          t_diff = t_end - t_start

          # ignore short tasks
          if t_diff > 10
            SC.logger.debug "#{indent}long task ~ #{name}: #{t_diff.to_i} msec"
          end
          self.class.outdent_logs

        end
      end
      return invocation_chain
    end
    protected :invoke_with_call_chain

    # Invoke all the prerequisites of a task.
    def invoke_prerequisites(task_args, invocation_chain) # :nodoc:
      @prerequisites.each { |n|
        prereq = application[n, @scope]
        prereq_args = task_args.new_scope(prereq.arg_names)
        invocation_chain = prereq.invoke_with_call_chain(prereq_args, invocation_chain)
      }
      return invocation_chain
    end

    # Format the trace flags for display.
    def format_trace_flags
      flags = []
      flags << "first_time" unless @already_invoked
      flags << "not_needed" unless needed?
      flags.empty? ? "" : "(" + flags.join(", ") + ")"
    end
    private :format_trace_flags

    # Execute the actions associated with this task.
    def execute(args=nil)

      @execute_count += 1
      args ||= EMPTY_TASK_ARGS
      return if SC.env[:dryrun]

      @actions.each do |act|
        case act.arity
        when 1
          act.call(self)
        else
          act.call(self, args)
        end
      end

    end

    # Is this task needed?
    def needed?
      true
    end

    # Timestamp for this task.  Basic tasks return the current time for their
    # time stamp.  Other tasks can be more sophisticated.
    def timestamp
      @prerequisites.collect { |p| application[p].timestamp }.max || Time.now
    end

    # Add a description to the task.  The description can consist of an option
    # argument list (enclosed brackets) and an optional comment.
    def add_description(description)
      return if ! description
      comment = description.strip
      add_comment(comment) if comment && ! comment.empty?
    end

    # Add task options.
    def add_options(task_options)
      return if !task_options
      @task_options = task_options
    end

    # Writing to the comment attribute is the same as adding a description.
    def comment=(description)
      add_description(description)
    end

    # Add a comment to the task.  If a comment alread exists, separate
    # the new comment with " / ".
    def add_comment(comment)
      if @full_comment
        @full_comment << " / "
      else
        @full_comment = ''
      end
      @full_comment << comment
      if @full_comment =~ /\A([^.]+?\.)( |$)/
        @comment = $1
      else
        @comment = @full_comment
      end
    end
    private :add_comment

    # Set the names of the arguments for this task. +args+ should be
    # an array of symbols, one for each argument name.
    def set_arg_names(args)
      @arg_names = args.map { |a| a.to_sym }
    end

    # Return a string describing the internal state of a task.  Useful for
    # debugging.
    def investigation
      result = "------------------------------\n"
      result << "Investigating #{name}\n"
      result << "class: #{self.class}\n"
      result <<  "task needed: #{needed?}\n"
      result <<  "timestamp: #{timestamp}\n"
      result << "pre-requisites: \n"
      prereqs = @prerequisites.collect {|name| application[name]}
      prereqs.sort! {|a,b| a.timestamp <=> b.timestamp}
      prereqs.each do |p|
        result << "--#{p.name} (#{p.timestamp})\n"
      end
      latest_prereq = @prerequisites.collect{|n| application[n].timestamp}.max
      result <<  "latest-prerequisite time: #{latest_prereq}\n"
      result << "................................\n\n"
      return result
    end

    class <<self

      # Apply the scope to the task name according to the rules for
      # this kind of task.  Generic tasks will accept the scope as
      # part of the name.
      def scope_name(scope, task_name)
        (scope + [task_name]).join(':')
      end

    end

  end

end


