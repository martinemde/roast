# frozen_string_literal: true

module Roast
  module Workflow
    class PromptStep < BaseStep
      def initialize(workflow, **kwargs)
        super(workflow, **kwargs)
      end

      def call
        prompt(name)
        result = chat_completion

        # Apply coercion if configured
        apply_coercion(result)
      end
    end
  end
end
