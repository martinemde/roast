# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Orchestrates all validators and aggregates results
      class ValidationOrchestrator
        attr_reader :errors, :warnings

        def initialize(yaml_content, workflow_path = nil)
          @yaml_content = yaml_content
          @workflow_path = workflow_path
          @errors = []
          @warnings = []
        end

        def valid?
          # First run schema validation
          schema_validator = SchemaValidator.new(@yaml_content, @workflow_path)

          unless schema_validator.valid?
            @errors = schema_validator.errors
            @warnings = schema_validator.warnings
            return false
          end

          parsed_yaml = schema_validator.instance_variable_get(:@parsed_yaml)

          # If schema is valid, run other validators
          if @errors.empty?
            step_collector = StepCollector.new(parsed_yaml)

            # Run dependency validation
            dependency_validator = DependencyValidator.new(parsed_yaml, @workflow_path, step_collector: step_collector)
            dependency_validator.validate
            @errors.concat(dependency_validator.errors)
            @warnings.concat(dependency_validator.warnings)

            # Run linting only if no errors
            if @errors.empty?
              linting_validator = LintingValidator.new(parsed_yaml, @workflow_path, step_collector: step_collector)
              linting_validator.validate
              @warnings.concat(linting_validator.warnings)
            end
          end

          @errors.empty?
        end
      end
    end
  end
end
