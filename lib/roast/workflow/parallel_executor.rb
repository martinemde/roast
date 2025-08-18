# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    # Executes workflow steps in parallel using threads
    class ParallelExecutor
      class << self
        def execute(steps, executor)
          new(executor).execute(steps)
        end
      end

      def initialize(executor)
        @executor = executor
      end

      def execute(steps)
        threads = steps.map do |sub_step|
          Thread.new do
            # Each thread needs its own isolated execution context
            Thread.current[:step] = sub_step
            Thread.current[:result] = nil
            Thread.current[:error] = nil

            begin
              # Execute the single step in this thread
              @executor.execute_steps([sub_step])
              Thread.current[:result] = :success
            rescue => e
              Thread.current[:error] = e
            end
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)

        # Check for errors in any thread
        threads.each_with_index do |thread, _index|
          if thread[:error]
            raise thread[:error]
          end
        end

        :success
      end
    end
  end
end
