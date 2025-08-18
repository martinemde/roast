# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    module StepExecutors
      class BaseStepExecutor
        def initialize(workflow_executor)
          @workflow_executor = workflow_executor
          @workflow = workflow_executor.workflow
          @config_hash = workflow_executor.config_hash
        end

        def execute(step)
          raise NotImplementedError, "Subclasses must implement execute"
        end

        protected

        attr_reader :workflow_executor, :workflow, :config_hash
      end
    end
  end
end
