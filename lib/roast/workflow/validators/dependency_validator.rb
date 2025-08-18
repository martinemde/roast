# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Validates dependencies: tools, step references, and resources
      class DependencyValidator < BaseValidator
        def initialize(parsed_yaml, workflow_path = nil, step_collector: nil)
          super(parsed_yaml, workflow_path)
          @step_collector = step_collector || StepCollector.new(parsed_yaml)
        end

        def validate
          validate_tool_dependencies
          validate_step_references
          validate_resource_dependencies
        end

        private

        def validate_tool_dependencies
          return unless @parsed_yaml["tools"]

          tools = extract_all_tools(@parsed_yaml["tools"])

          tools.each do |tool|
            next if tool_available?(tool)

            add_error(
              type: :tool_dependency,
              tool: tool,
              message: "Tool '#{tool}' is not available",
              suggestion: suggest_tool_fix(tool),
            )
          end
        end

        def validate_step_references
          all_steps = @step_collector.all_steps
          step_names = all_steps.map { |s| extract_step_name(s) }.compact.uniq

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

                add_error(
                  type: :step_reference,
                  message: "Step '#{condition}' referenced in #{condition_key} condition does not exist",
                  suggestion: "Ensure step '#{condition}' is defined before it's referenced",
                )
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
            add_warning(
              type: :resource,
              message: "Target file '#{target}' does not exist",
              suggestion: "Ensure the target file exists or use a glob pattern",
            )
          end
        end

        def validate_prompt_files
          workflow_dir = File.dirname(@workflow_path)
          all_steps = @step_collector.all_steps

          all_steps.each do |step|
            next unless step.is_a?(String)

            # Check if corresponding prompt file exists
            prompt_path = File.join(workflow_dir, step, "prompt.md")
            next if File.exist?(prompt_path)

            add_warning(
              type: :resource,
              message: "Prompt file missing for step '#{step}'",
              suggestion: "Create file: #{prompt_path}",
            )
          end
        end
      end
    end
  end
end
