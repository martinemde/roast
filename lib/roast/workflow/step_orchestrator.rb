# frozen_string_literal: true

require "roast/workflow/step_executor_factory"

module Roast
  module Workflow
    # Handles the orchestration of step execution, managing the flow and control
    # of individual steps without knowing how to execute them
    class StepOrchestrator
      def initialize(workflow, step_loader, state_manager, error_handler, workflow_executor)
        @workflow = workflow
        @step_loader = step_loader
        @state_manager = state_manager
        @error_handler = error_handler
        @workflow_executor = workflow_executor
      end

      def execute_step(name, exit_on_error: true)
        resource_type = @workflow.respond_to?(:resource) ? @workflow.resource&.type : nil

        @error_handler.with_error_handling(name, resource_type: resource_type) do
          $stderr.puts "Executing: #{name} (Resource type: #{resource_type || "unknown"})"

          step_object = @step_loader.load(name)
          step_result = step_object.call

          # Store result in workflow output
          @workflow.output[name] = step_result

          # Save state after each step
          @state_manager.save_state(name, step_result)

          step_result
        end
      end

      def execute_steps(workflow_steps)
        workflow_steps.each do |workflow_step|
          executor = StepExecutorFactory.for(workflow_step, @workflow_executor)
          executor.execute(workflow_step)

          # Handle pause after string steps
          if workflow_step.is_a?(String) && @workflow.pause_step_name == workflow_step
            Kernel.binding.irb # rubocop:disable Lint/Debugger
          end
        end
      end
    end
  end
end
