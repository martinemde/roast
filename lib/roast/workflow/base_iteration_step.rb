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

      # Process various types of inputs and convert to appropriate types for iteration
      def process_iteration_input(input, context, coerce_to: nil)
        if input.is_a?(String)
          # Case 1: Ruby expression in {{}}
          if input.strip.start_with?("{{") && input.strip.end_with?("}}")
            expression = input.strip[2...-2].strip
            result = evaluate_ruby_expression(expression, context)
            coerce_result(result, coerce_to)

          # Case 2: Bash command in $()
          elsif input.strip.start_with?("$(") && input.strip.end_with?(")")
            command = input.strip[2...-1].strip
            execute_command(command, coerce_to)

          # Case 3: Step name or prompt
          else
            # Use existing workflow executor to run the step
            step_result = execute_step_by_name(input, context)
            coerce_result(step_result, coerce_to)
          end
        else
          # Non-string inputs are returned as-is
          coerce_result(input, coerce_to)
        end
      end

      # Legacy method for backward compatibility
      # Will be deprecated in future versions in favor of process_iteration_input
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

      private

      # Execute a Ruby expression in the workflow context
      def evaluate_ruby_expression(expression, context)
        context.instance_eval(expression)
      rescue => e
        $stderr.puts "Warning: Error evaluating expression '#{expression}': #{e.message}"
        nil
      end

      # Execute a bash command and return its result
      def execute_command(command, coerce_to)
        # Use existing command execution functionality
        cmd_tool = Roast::Tools::Cmd.new
        result = cmd_tool.call(command: command)

        if coerce_to == :boolean
          # For boolean coercion, use exit status
          cmd_tool.last_status.success?
        else
          # For other uses, return the output
          result
        end
      end

      # Execute a step by name and return its result
      def execute_step_by_name(step_name, context)
        # Reuse existing step execution logic
        executor = WorkflowExecutor.new(context, {}, context_path)
        executor.execute_step(step_name)
      end

      # Coerce results to the appropriate type
      def coerce_result(result, coerce_to)
        case coerce_to
        when :boolean
          !!result # Force to boolean
        when :iterable
          # Convert to iterable if not already
          unless result.respond_to?(:each)
            return result.to_s.split("\n")
          end

          result
        when :llm_boolean
          # Stub for LLM boolean coercion
          # TODO: Implement proper LLM response to boolean conversion
          !!result
        else
          result
        end
      end
    end
  end
end
