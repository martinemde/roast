# frozen_string_literal: true

module Roast
  module Workflow
    # Comprehensive validator for workflow configurations
    # Performs multiple levels of validation:
    # 1. Schema validation (using JSON Schema)
    # 2. Dependency checking (tools, steps, resources)
    # 3. Configuration linting (best practices)
    # 4. Clear error messaging with guidance
    class ComprehensiveValidator
      attr_reader :errors, :warnings

      def initialize(yaml_content, workflow_path = nil)
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

      def valid?
        return false if @parsed_yaml.empty?

        # Run all validation checks
        validate_schema
        validate_dependencies if @errors.empty?
        lint_configuration if @errors.empty?

        @errors.empty?
      end

      private

      def validate_schema
        validator = Validator.new(@yaml_content)
        unless validator.valid?
          validator.errors.each do |error|
            @errors << format_schema_error(error)
          end
        end
      end

      def validate_dependencies
        validate_tool_dependencies
        validate_step_references
        validate_resource_dependencies
      end

      def validate_tool_dependencies
        return unless @parsed_yaml["tools"]

        tools = extract_all_tools(@parsed_yaml["tools"])

        tools.each do |tool|
          next if tool_available?(tool)

          @errors << {
            type: :tool_dependency,
            tool: tool,
            message: "Tool '#{tool}' is not available",
            suggestion: suggest_tool_fix(tool),
          }
        end
      end

      def validate_step_references
        all_steps = collect_all_steps(@parsed_yaml)
        step_names = all_steps.map { |s| extract_step_name(s) }.compact.uniq

        # Check for step references in the entire configuration
        check_step_references_in_config(@parsed_yaml, step_names)
      end

      def validate_resource_dependencies
        # Validate file resources if target is specified
        if @parsed_yaml["target"] && @workflow_path
          validate_target_resource(@parsed_yaml["target"])
        end

        # Validate prompt files exist
        validate_prompt_files if @workflow_path
      end

      def lint_configuration
        lint_naming_conventions
        lint_step_complexity
        lint_tool_usage
        lint_common_mistakes
      end

      def lint_naming_conventions
        # Check workflow name
        if @parsed_yaml["name"].nil? || @parsed_yaml["name"].empty?
          @warnings << {
            type: :naming,
            message: "Workflow should have a descriptive name",
            suggestion: "Add a 'name' field to your workflow configuration",
          }
        end

        # Check step naming
        all_steps = collect_all_steps(@parsed_yaml)
        all_steps.each do |step|
          next unless step.is_a?(String) && !step.match?(/^[a-z_]+$/)

          @warnings << {
            type: :naming,
            step: step,
            message: "Step name '#{step}' should use snake_case",
            suggestion: "Rename to '#{step.downcase.gsub(/[^a-z0-9]/, "_")}'",
          }
        end
      end

      def lint_step_complexity
        # Check for overly complex workflows
        all_steps = collect_all_steps(@parsed_yaml)
        if all_steps.size > 20
          @warnings << {
            type: :complexity,
            message: "Workflow has #{all_steps.size} steps, consider breaking it into smaller workflows",
            suggestion: "Use sub-workflows or modularize complex logic",
          }
        end

        # Check for deeply nested conditions
        check_nesting_depth(@parsed_yaml["steps"] || [])
      end

      def lint_tool_usage
        tools = @parsed_yaml["tools"] || []

        # Check for unused tools
        if tools.any?
          used_tools = detect_used_tools
          unused_tools = extract_all_tools(tools) - used_tools

          unused_tools.each do |tool|
            @warnings << {
              type: :unused_tool,
              tool: tool,
              message: "Tool '#{tool}' is declared but never used",
              suggestion: "Remove unused tool or use it in your workflow",
            }
          end
        end
      end

      def lint_common_mistakes
        # Check for common configuration mistakes

        # Missing error handling
        if !@parsed_yaml["exit_on_error"] && !has_error_handling?
          @warnings << {
            type: :error_handling,
            message: "No error handling configured",
            suggestion: "Consider adding 'exit_on_error: true' or error handling steps",
          }
        end

        # Check for hardcoded values that should be inputs
        check_hardcoded_values
      end

      # Helper methods

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
          # Extract property name from error like: "The property '#/' did not contain a required property of 'steps'"
          property = error.match(/required property of '([^']+)'/)[1]
          {
            type: :schema,
            message: "Missing required field: '#{property}'",
            suggestion: "Add '#{property}' to your workflow configuration",
          }
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

      def tool_available?(tool_name)
        # Check if it's an MCP tool first
        tools_config = @parsed_yaml["tools"] || []
        tools_config.each do |tool_entry|
          if tool_entry.is_a?(Hash) && tool_entry.keys.include?(tool_name)
            # It's an MCP tool configuration
            return true
          end
        end

        # Check if tool module exists
        begin
          tool_name.constantize
          true
        rescue NameError
          false
        end
      end

      def suggest_tool_fix(tool)
        # Suggest similar tools or common fixes
        available_tools = [
          "Roast::Tools::Bash",
          "Roast::Tools::Cmd",
          "Roast::Tools::ReadFile",
          "Roast::Tools::WriteFile",
          "Roast::Tools::UpdateFiles",
          "Roast::Tools::SearchFile",
          "Roast::Tools::Grep",
          "Roast::Tools::AskUser",
          "Roast::Tools::CodingAgent",
        ]

        # Simple similarity check
        tool_base = tool.split("::").last&.downcase || tool.downcase
        suggestions = available_tools.select do |t|
          t_base = t.split("::").last&.downcase || ""
          t_base.include?(tool_base) || tool_base.include?(t_base)
        end

        if suggestions.any?
          "Did you mean: #{suggestions.join(", ")}?"
        else
          "Ensure the tool module exists or check the tool name spelling"
        end
      end

      def extract_all_tools(tools_config)
        tools = []
        tools_config.each do |tool_entry|
          case tool_entry
          when String
            tools << tool_entry
          when Hash
            tool_entry.each_key do |tool_name|
              tools << tool_name
            end
          end
        end
        tools
      end

      def collect_all_steps(config, steps = [])
        # Recursively collect all steps from the configuration
        ["steps", "pre_processing", "post_processing"].each do |key|
          if config[key]
            steps.concat(extract_steps_from_array(config[key]))
          end
        end
        steps
      end

      def extract_steps_from_array(steps_array, collected = [])
        steps_array.each do |step|
          case step
          when String
            collected << step
          when Hash
            if step["steps"]
              collected.concat(extract_steps_from_array(step["steps"]))
            end
            # Handle conditional steps
            ["then", "else", "true", "false"].each do |branch|
              if step[branch]
                collected.concat(extract_steps_from_array(step[branch]))
              end
            end
            # Handle case/when steps
            step["when"]&.each_value do |when_steps|
              collected.concat(extract_steps_from_array(when_steps))
            end
          when Array
            collected.concat(extract_steps_from_array(step))
          end
        end
        collected
      end

      def extract_step_name(step)
        case step
        when String
          step
        when Hash
          # Complex step types don't have simple names
          nil
        end
      end

      def check_step_references_in_config(config, valid_step_names)
        # Check steps array
        ["steps", "pre_processing", "post_processing"].each do |key|
          if config[key].is_a?(Array)
            check_step_references(config[key], valid_step_names)
          end
        end
      end

      def check_step_references(steps, valid_step_names, path = [])
        steps.each_with_index do |step, index|
          current_path = path + [index]

          case step
          when Hash
            # Check conditions that might reference steps
            ["if", "unless", "case"].each do |condition_key|
              next unless step[condition_key]

              condition = step[condition_key]
              next unless condition.is_a?(String) && !condition.include?("{{") && !condition.include?("$(")

              # Check if it looks like a step reference (snake_case identifier)
              # and is not a known boolean value
              next unless condition.match?(/^[a-z_]+$/) && !["true", "false", "yes", "no", "on", "off"].include?(condition)

              # This looks like it could be a step reference
              next if valid_step_names.include?(condition)

              @errors << {
                type: :step_reference,
                message: "Step '#{condition}' referenced in #{condition_key} condition does not exist",
                suggestion: "Ensure step '#{condition}' is defined before it's referenced",
              }
            end

            # Check nested steps
            ["then", "else", "steps"].each do |key|
              if step[key].is_a?(Array)
                check_step_references(step[key], valid_step_names, current_path + [key])
              end
            end

            # Check case/when branches
            if step["when"].is_a?(Hash)
              step["when"].each do |when_value, when_steps|
                if when_steps.is_a?(Array)
                  check_step_references(when_steps, valid_step_names, current_path + ["when", when_value])
                end
              end
            end
          when Array
            check_step_references(step, valid_step_names, current_path)
          end
        end
      end

      def validate_target_resource(target)
        return unless @workflow_path

        workflow_dir = File.dirname(@workflow_path)

        # If target is a glob pattern or shell command, skip file validation
        return if target.include?("*") || target.start_with?("$(")

        target_path = File.expand_path(target, workflow_dir)
        unless File.exist?(target_path)
          @warnings << {
            type: :resource,
            message: "Target file '#{target}' does not exist",
            suggestion: "Ensure the target file exists or use a glob pattern",
          }
        end
      end

      def validate_prompt_files
        workflow_dir = File.dirname(@workflow_path)
        all_steps = collect_all_steps(@parsed_yaml)

        all_steps.each do |step|
          next unless step.is_a?(String)

          # Check if corresponding prompt file exists
          prompt_path = File.join(workflow_dir, step, "prompt.md")
          next if File.exist?(prompt_path)

          @warnings << {
            type: :resource,
            message: "Prompt file missing for step '#{step}'",
            suggestion: "Create file: #{prompt_path}",
          }
        end
      end

      def check_nesting_depth(steps, depth = 0)
        max_depth = 5

        steps.each do |step|
          next unless step.is_a?(Hash)

          current_depth = depth + 1

          if current_depth > max_depth
            @warnings << {
              type: :complexity,
              message: "Excessive nesting depth (#{current_depth} levels)",
              suggestion: "Consider extracting nested logic into separate steps or workflows",
            }
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

      def detect_used_tools
        # This would require more sophisticated analysis of prompt content
        # For now, return empty array
        []
      end

      def has_error_handling?
        # Check if workflow has any error handling mechanisms
        all_steps = collect_all_steps(@parsed_yaml)
        all_steps.any? do |step|
          step.is_a?(Hash) && (step["rescue"] || step["ensure"])
        end
      end

      def check_hardcoded_values
        # Check for common hardcoded values that should be inputs
        hardcoded_patterns = {
          /api[_-]?key/i => "API keys should be provided via inputs or environment variables",
          /password/i => "Passwords should not be hardcoded",
          /secret/i => "Secrets should not be hardcoded",
          /token/i => "Tokens should be provided via inputs or environment variables",
        }

        yaml_string = @yaml_content
        hardcoded_patterns.each do |pattern, message|
          next unless yaml_string.match?(pattern)

          @warnings << {
            type: :security,
            message: message,
            suggestion: "Use inputs or environment variables for sensitive data",
          }
          break # Only report once per workflow
        end
      end
    end
  end
end
