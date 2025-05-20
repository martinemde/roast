# frozen_string_literal: true

require_relative "workflow_executor"

module Roast
  module Workflow
    # Base class for iteration steps (RepeatStep and EachStep)
    class BaseIterationStep < BaseStep
      DEFAULT_MAX_ITERATIONS = 100

      attr_reader :steps

      def initialize(workflow, steps:, **kwargs)
        super(workflow, **kwargs)
        @steps = steps
      end

      protected

      # Evaluates a condition string in the context of the workflow
      def evaluate_condition(condition_expr, context)
        # Just use instance_eval directly on the workflow
        context.instance_eval(condition_expr)
      rescue => e
        $stderr.puts "Warning: Error evaluating condition '#{condition_expr}': #{e.message}"
        false # Return false if evaluation fails (continue looping)
      end

      # Interpolates {{expression}} in a string with values from the workflow context
      def interpolate_expression(text, context)
        return text unless text.is_a?(String) && text.include?("{{") && text.include?("}}")

        # Replace all {{expression}} with their evaluated values
        text.gsub(/\{\{([^}]+)\}\}/) do |match|
          expression = Regexp.last_match(1).strip
          begin
            # Evaluate the expression in the workflow's context
            result = context.instance_eval(expression)
            result.inspect # Convert to string representation
          rescue => e
            $stderr.puts "Warning: Error interpolating {{#{expression}}}: #{e.message}"
            match # Return the original match to preserve it in the string
          end
        end
      end

      # Execute nested steps
      def execute_nested_steps(steps, context, executor = nil)
        executor ||= WorkflowExecutor.new(context, {}, context_path)
        results = []

        steps.each do |step|
          result = case step
          when String
            executor.execute_step(step)
          when Hash, Array
            executor.execute_steps([step])
          end
          results << result
        end

        results
      end
    end
  end
end
