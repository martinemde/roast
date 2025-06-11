# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Validates workflow configuration for best practices and common issues
      class LintingValidator < BaseValidator
        # Configurable thresholds
        MAX_STEPS = 20
        MAX_NESTING_DEPTH = 5

        def initialize(parsed_yaml, workflow_path = nil, step_collector: nil)
          super(parsed_yaml, workflow_path)
          @step_collector = step_collector || StepCollector.new(parsed_yaml)
        end

        def validate
          lint_naming_conventions
          lint_step_complexity
          lint_common_mistakes
        end

        private

        def lint_naming_conventions
          # Check workflow name
          if @parsed_yaml["name"].nil? || @parsed_yaml["name"].empty?
            add_warning(
              type: :naming,
              message: "Workflow should have a descriptive name",
              suggestion: "Add a 'name' field to your workflow configuration",
            )
          end

          # Check step naming
          all_steps = @step_collector.all_steps
          all_steps.each do |step|
            next unless step.is_a?(String) && !step.match?(/^[a-z_]+$/)

            add_warning(
              type: :naming,
              step: step,
              message: "Step name '#{step}' should use snake_case",
              suggestion: "Rename to '#{step.downcase.gsub(/[^a-z0-9]/, "_")}'",
            )
          end
        end

        def lint_step_complexity
          # Check for overly complex workflows
          all_steps = @step_collector.all_steps
          if all_steps.size > MAX_STEPS
            add_warning(
              type: :complexity,
              message: "Workflow has #{all_steps.size} steps, consider breaking it into smaller workflows",
              suggestion: "Use sub-workflows or modularize complex logic",
            )
          end

          # Check for deeply nested conditions
          check_nesting_depth(@parsed_yaml["steps"] || [])
        end

        def lint_common_mistakes
          # Missing error handling
          if !@parsed_yaml["exit_on_error"] && !error_handling?
            add_warning(
              type: :error_handling,
              message: "No error handling configured",
              suggestion: "Consider adding 'exit_on_error: true' or error handling steps",
            )
          end
        end

        def check_nesting_depth(steps, depth = 0)
          steps.each do |step|
            next unless step.is_a?(Hash)

            current_depth = depth + 1

            if current_depth > MAX_NESTING_DEPTH
              add_warning(
                type: :complexity,
                message: "Excessive nesting depth (#{current_depth} levels)",
                suggestion: "Consider extracting nested logic into separate steps or workflows",
              )
            end

            # Check nested steps
            ["steps", "then", "else", "true", "false"].each do |key|
              check_nesting_depth(step[key], current_depth) if step[key].is_a?(Array)
            end

            # Check case/when branches
            next unless step["when"]

            step["when"].each_value do |when_steps|
              check_nesting_depth(when_steps, current_depth) if when_steps.is_a?(Array)
            end
          end
        end

        def error_handling?
          # Check if workflow has any error handling mechanisms
          all_steps = @step_collector.all_steps
          all_steps.any? do |step|
            step.is_a?(Hash) && (step["rescue"] || step["ensure"])
          end
        end
      end
    end
  end
end
