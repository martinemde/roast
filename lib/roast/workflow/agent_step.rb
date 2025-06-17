# frozen_string_literal: true

module Roast
  module Workflow
    class AgentStep < BaseStep
      def call
        # For inline prompts (detected by plain text step names), use the name as the prompt
        # For file-based steps, load from the prompt file
        prompt_content = if name.plain_text?
          name.to_s
        else
          read_sidecar_prompt
        end

        # Extract agent-specific configuration from workflow config
        step_config = workflow.config[name.to_s] || {}
        agent_options = {
          include_context_summary: step_config.fetch("include_context_summary", false),
          continue: step_config.fetch("continue", false),
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
