# frozen_string_literal: true

module Roast
  module Workflow
    # Factory for creating step instances based on step characteristics
    class StepFactory
      class << self
        # Create a step instance based on the step type and characteristics
        #
        # @param workflow [BaseWorkflow] The workflow instance
        # @param step_name [String, StepName] The name of the step
        # @param options [Hash] Additional options for step creation
        # @return [BaseStep] The appropriate step instance
        def create(workflow, step_name, options = {})
          name = normalize_step_name(step_name)

          # Determine the step class based on characteristics
          step_class = determine_step_class(name, options)

          # Create the step instance with appropriate parameters
          build_step_instance(step_class, workflow, name, options)
        end

        private

        def normalize_step_name(step_name)
          step_name.is_a?(Roast::ValueObjects::StepName) ? step_name : Roast::ValueObjects::StepName.new(step_name)
        end

        def determine_step_class(name, options)
          # Check if this is an agent step (indicated by special processing needs)
          if options[:agent_type] == :coding_agent
            Roast::Workflow::AgentStep
          elsif name.plain_text?
            # Plain text steps are always prompt steps
            options[:agent_type] == :coding_agent ? Roast::Workflow::AgentStep : Roast::Workflow::PromptStep
          else
            # Default to BaseStep for directory-based steps
            Roast::Workflow::BaseStep
          end
        end

        def build_step_instance(step_class, workflow, name, options)
          step_params = {
            name: name.to_s,
          }

          # Add context path if provided
          step_params[:context_path] = options[:context_path] if options[:context_path]

          step_class.new(workflow, **step_params)
        end
      end
    end
  end
end
