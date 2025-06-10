# frozen_string_literal: true

module Roast
  module Workflow
    class AgentStep < BaseStep
      def initialize(workflow, **kwargs)
        super(workflow, **kwargs)
      end

      def call
        # Load the prompt content
        prompt_content = read_sidecar_prompt

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
