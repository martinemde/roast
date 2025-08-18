# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    # Handles execution of input steps
    class InputExecutor
      def initialize(workflow, context_path, state_manager, workflow_executor = nil)
        @workflow = workflow
        @context_path = context_path
        @state_manager = state_manager
        @workflow_executor = workflow_executor
      end

      def execute_input(input_config)
        # Interpolate the prompt if workflow executor is available
        if @workflow_executor && input_config["prompt"]
          interpolated_config = input_config.dup
          interpolated_config["prompt"] = @workflow_executor.interpolate(input_config["prompt"])
        else
          interpolated_config = input_config
        end

        # Create and execute an InputStep
        input_step = InputStep.new(
          @workflow,
          config: interpolated_config,
          name: input_config["name"] || "input_#{Time.now.to_i}",
          context_path: @context_path,
        )

        result = input_step.call

        # Store in 'previous' for conditional checks
        @workflow.output["previous"] = result
        @state_manager.save_state("previous", result)

        result
      end
    end
  end
end
