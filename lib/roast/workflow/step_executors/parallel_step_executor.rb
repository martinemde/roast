# frozen_string_literal: true

require "roast/workflow/step_executors/base_step_executor"

module Roast
  module Workflow
    module StepExecutors
      class ParallelStepExecutor < BaseStepExecutor
        def execute(steps)
          # run steps in parallel, don't proceed until all are done
          steps.map do |sub_step|
            Thread.new { workflow_executor.execute_steps([sub_step]) }
          end.each(&:join)
        end
      end
    end
  end
end
