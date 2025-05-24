# frozen_string_literal: true

require "roast/workflow/base_iteration_step"

module Roast
  module Workflow
    class ConditionalStep < BaseIterationStep
      def initialize(workflow, config:, name:, context_path:, **kwargs)
        # Extract steps for parent class (use then_steps as default)
        steps = config["then"] || []
        super(workflow, steps: steps, name: name, context_path: context_path, **kwargs)

        @config = config
        @condition = config["if"] || config["unless"]
        @is_unless = config.key?("unless")
        @then_steps = config["then"] || []
        @else_steps = config["else"] || []
      end

      def call
        # Evaluate the condition using the inherited process_iteration_input method
        condition_result = process_iteration_input(@condition, @workflow, coerce_to: :boolean)

        # Invert the result if this is an 'unless' condition
        condition_result = !condition_result if @is_unless

        # Select which steps to execute based on the condition
        steps_to_execute = condition_result ? @then_steps : @else_steps

        # Execute the selected steps
        unless steps_to_execute.empty?
          # Execute the steps using the workflow's execute_steps method
          @workflow.execute_steps(steps_to_execute)
        end

        # Return a result indicating which branch was taken
        { condition_result: condition_result, branch_executed: condition_result ? "then" : "else" }
      end
    end
  end
end
