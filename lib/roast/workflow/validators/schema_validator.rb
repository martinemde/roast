# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Validates workflow configuration against JSON schema
      class SchemaValidator < BaseValidator
        attr_reader :parsed_yaml

        def initialize(yaml_content, workflow_path = nil) # rubocop:disable Lint/MissingSuper
          @yaml_content = yaml_content&.strip || ""
          @workflow_path = workflow_path
          @errors = []
          @warnings = []

          begin
            @parsed_yaml = @yaml_content.empty? ? {} : YAML.safe_load(@yaml_content)
          rescue Psych::SyntaxError => e
            @errors << format_yaml_error(e)
            @parsed_yaml = {}
          end
        end

        def validate
          if @parsed_yaml.empty?
            @errors << {
              type: :empty_configuration,
              message: "Workflow configuration is empty",
              suggestion: "Provide a valid workflow configuration with required fields: name, tools, and steps",
            }
            return
          end

          validator = Validator.new(@yaml_content)
          unless validator.valid?
            validator.errors.each do |error|
              @errors << format_schema_error(error)
            end
          end
        end

        private

        def format_yaml_error(error)
          {
            type: :yaml_syntax,
            message: "YAML syntax error: #{error.message}",
            line: error.line,
            column: error.column,
            suggestion: "Check YAML syntax at line #{error.line}, column #{error.column}",
          }
        end

        def format_schema_error(error)
          # Parse JSON Schema error and make it more user-friendly
          if error.include?("did not contain a required property")
            # Extract property name from error
            match = error.match(/required property of '([^']+)'/)
            if match
              property = match[1]
              {
                type: :schema,
                message: "Missing required field: '#{property}'",
                suggestion: "Add '#{property}' to your workflow configuration",
              }
            else
              {
                type: :schema,
                message: error,
                suggestion: "Check the required fields in your workflow configuration",
              }
            end
          elsif error.include?("does not match")
            {
              type: :schema,
              message: error,
              suggestion: "Check the workflow schema documentation for valid values",
            }
          else
            {
              type: :schema,
              message: error,
              suggestion: "Refer to the workflow schema for correct configuration structure",
            }
          end
        end
      end
    end
  end
end
