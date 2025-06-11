# frozen_string_literal: true

require "forwardable"

module Roast
  module Workflow
    # Legacy wrapper for backward compatibility
    # Delegates to the new ValidationOrchestrator
    class ComprehensiveValidator
      extend Forwardable

      def_delegators :@orchestrator, :errors, :warnings, :valid?

      def initialize(yaml_content, workflow_path = nil)
        @orchestrator = Validators::ValidationOrchestrator.new(yaml_content, workflow_path)
      end
    end
  end
end
