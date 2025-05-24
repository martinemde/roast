# frozen_string_literal: true

module Roast
  module Workflow
    # Handles execution of iteration steps (repeat and each)
    class IterationExecutor
      def initialize(workflow, context_path, state_manager)
        @workflow = workflow
        @context_path = context_path
        @state_manager = state_manager
      end

      def execute_repeat(repeat_config)
        $stderr.puts "Executing repeat step: #{repeat_config.inspect}"

        # Extract parameters from the repeat configuration
        steps = repeat_config["steps"]
        until_condition = repeat_config["until"]
        max_iterations = repeat_config["max_iterations"] || BaseIterationStep::DEFAULT_MAX_ITERATIONS

        # Verify required parameters
        raise WorkflowExecutor::ConfigurationError, "Missing 'steps' in repeat configuration" unless steps
        raise WorkflowExecutor::ConfigurationError, "Missing 'until' condition in repeat configuration" unless until_condition

        # Create and execute a RepeatStep
        require "roast/workflow/repeat_step" unless defined?(RepeatStep)
        repeat_step = RepeatStep.new(
          @workflow,
          steps: steps,
          until_condition: until_condition,
          max_iterations: max_iterations,
          name: "repeat_#{@workflow.output.size}",
          context_path: @context_path,
        )

        results = repeat_step.call

        # Store results in workflow output
        step_name = "repeat_#{until_condition.gsub(/[^a-zA-Z0-9_]/, "_")}"
        @workflow.output[step_name] = results

        # Save state
        @state_manager.save_state(step_name, results)

        results
      end

      def execute_each(each_config)
        $stderr.puts "Executing each step: #{each_config.inspect}"

        # Extract parameters from the each configuration
        collection_expr = each_config["each"]
        variable_name = each_config["as"]
        steps = each_config["steps"]

        # Verify required parameters
        raise WorkflowExecutor::ConfigurationError, "Missing collection expression in each configuration" unless collection_expr
        raise WorkflowExecutor::ConfigurationError, "Missing 'as' variable name in each configuration" unless variable_name
        raise WorkflowExecutor::ConfigurationError, "Missing 'steps' in each configuration" unless steps

        # Create and execute an EachStep
        require "roast/workflow/each_step" unless defined?(EachStep)
        each_step = EachStep.new(
          @workflow,
          collection_expr: collection_expr,
          variable_name: variable_name,
          steps: steps,
          name: "each_#{variable_name}",
          context_path: @context_path,
        )

        results = each_step.call

        # Store results in workflow output
        step_name = "each_#{variable_name}"
        @workflow.output[step_name] = results

        # Save state
        @state_manager.save_state(step_name, results)

        results
      end
    end
  end
end
