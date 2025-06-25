# frozen_string_literal: true

module Roast
  module Workflow
    class AgentStep < BaseStep
      attr_accessor :include_context_summary, :continue

      def initialize(workflow, **kwargs)
        super
        # Set default values for agent-specific options
        @include_context_summary = false
        @continue = false
      end

      def call
        # For inline prompts (detected by plain text step names), use the name as the prompt
        # For file-based steps, load from the prompt file
        prompt_content = if name.plain_text?
          name.to_s
        else
          read_sidecar_prompt
        end

        # Use agent-specific configuration that was applied by StepLoader
        agent_options = {
          include_context_summary: @include_context_summary,
          continue: @continue,
        }

        # Call CodingAgent directly with the prompt content and options
        result = Roast::Tools::CodingAgent.call(prompt_content, **agent_options)

        # Process output if print_response is enabled
        process_output(result, print_response:)

        # Apply coercion if configured
        apply_coercion(result)
      end
    end
  end
end
