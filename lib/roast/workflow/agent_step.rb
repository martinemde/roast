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

        # Call CodingAgent directly with the prompt content
        result = Roast::Tools::CodingAgent.call(prompt_content)

        # Process output if print_response is enabled
        process_output(result, print_response:)

        # Apply coercion if configured
        apply_coercion(result)
      end
    end
  end
end
