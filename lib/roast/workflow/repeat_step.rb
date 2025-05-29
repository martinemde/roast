# frozen_string_literal: true

module Roast
  module Workflow
    # Executes steps repeatedly until a condition is met or max_iterations is reached
    class RepeatStep < BaseIterationStep
      attr_reader :until_condition, :max_iterations

      def initialize(workflow, steps:, until_condition:, max_iterations: DEFAULT_MAX_ITERATIONS, **kwargs)
        super(workflow, steps: steps, **kwargs)
        @until_condition = until_condition
        @max_iterations = max_iterations.to_i

        # Ensure max_iterations is at least 1
        @max_iterations = 1 if @max_iterations < 1
      end

      def call
        iteration = 0
        results = []

        $stderr.puts "Starting repeat loop with max_iterations: #{@max_iterations}"

        begin
          # Loop until condition is met or max_iterations is reached
          # Process the until_condition based on its type with configured coercion
          until process_iteration_input(@until_condition, workflow, coerce_to: @coerce_to) || (iteration >= @max_iterations)
            $stderr.puts "Repeat loop iteration #{iteration + 1}"

            # Execute the nested steps
            step_results = execute_nested_steps(@steps, workflow)
            results << step_results

            # Increment iteration counter
            iteration += 1

            # Save state after each iteration if the workflow supports it
            save_iteration_state(iteration) if workflow.respond_to?(:session_name) && workflow.session_name
          end

          if iteration >= @max_iterations
            $stderr.puts "Repeat loop reached maximum iterations (#{@max_iterations})"
          else
            $stderr.puts "Repeat loop condition satisfied after #{iteration} iterations"
          end

          # Return the results of all iterations
          results
        rescue => e
          $stderr.puts "Error in repeat loop: #{e.message}"
          raise
        end
      end

      private

      def save_iteration_state(iteration)
        state_repository = FileStateRepository.new

        # Save the current iteration count in the state
        state_data = {
          step_name: name,
          iteration: iteration,
          output: workflow.respond_to?(:output) ? workflow.output.clone : {},
          transcript: workflow.respond_to?(:transcript) ? workflow.transcript.map(&:itself) : [],
        }

        state_repository.save_state(workflow, "#{name}_iteration_#{iteration}", state_data)
      rescue => e
        # Don't fail the workflow if state saving fails
        $stderr.puts "Warning: Failed to save iteration state: #{e.message}"
      end
    end
  end
end
