# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class ComprehensiveValidatorTest < ActiveSupport::TestCase
      def setup
        @valid_yaml = <<~YAML
          name: Test Workflow
          tools:
            - Roast::Tools::Bash
            - Roast::Tools::ReadFile
          steps:
            - first_step
            - second_step
        YAML

        @workflow_path = "/tmp/test_workflow.yml"
      end

      test "validates valid workflow successfully" do
        validator = ComprehensiveValidator.new(@valid_yaml, @workflow_path)
        assert validator.valid?
        assert_empty validator.errors
      end

      test "catches YAML syntax errors" do
        invalid_yaml = "name: - test"
        validator = ComprehensiveValidator.new(invalid_yaml, @workflow_path)

        refute validator.valid?
        assert validator.errors.size >= 1
        yaml_error = validator.errors.find { |e| e[:type] == :yaml_syntax }
        assert yaml_error, "Expected YAML syntax error"
      end

      test "catches missing required fields" do
        yaml = <<~YAML
          name: Test Workflow
          tools:
            - Roast::Tools::Bash
        YAML

        validator = ComprehensiveValidator.new(yaml, @workflow_path)
        refute validator.valid?

        error = validator.errors.find { |e| e[:message].include?("Missing required field: 'steps'") }
        assert error
        assert_equal :schema, error[:type]
      end

      test "validates tool dependencies" do
        yaml_with_invalid_tool = <<~YAML
          name: Test Workflow
          tools:
            - Roast::Tools::Bash
            - NonExistentTool
          steps:
            - first_step
        YAML

        validator = ComprehensiveValidator.new(yaml_with_invalid_tool, @workflow_path)
        refute validator.valid?

        error = validator.errors.find { |e| e[:type] == :tool_dependency }
        assert error
        assert_includes error[:message], "NonExistentTool"
      end

      test "validates step references in conditions" do
        yaml_with_invalid_ref = <<~YAML
          name: Test Workflow
          tools: []
          steps:
            - if: non_existent_step
              then:
                - some_action
        YAML

        validator = ComprehensiveValidator.new(yaml_with_invalid_ref, @workflow_path)

        refute validator.valid?, "Expected validation to fail for invalid step reference. Errors: #{validator.errors.inspect}"

        error = validator.errors.find { |e| e[:type] == :step_reference }
        assert error, "Expected step_reference error but got: #{validator.errors.inspect}"
        assert_includes error[:message], "non_existent_step"
      end

      test "warns about missing workflow name" do
        yaml_without_name = <<~YAML
          name: ""
          tools:
            - Roast::Tools::Bash
          steps:
            - first_step
        YAML

        validator = ComprehensiveValidator.new(yaml_without_name, @workflow_path)
        assert validator.valid? # Still valid, just has warnings

        warning = validator.warnings.find { |w| w[:type] == :naming }
        assert warning
        assert_includes warning[:message], "should have a descriptive name"
      end

      test "warns about non-snake_case step names" do
        yaml_with_camelcase = <<~YAML
          name: Test Workflow
          tools: []
          steps:
            - FirstStep
            - second-step
            - third_step
        YAML

        validator = ComprehensiveValidator.new(yaml_with_camelcase, @workflow_path)
        assert validator.valid?

        warnings = validator.warnings.select { |w| w[:type] == :naming && w[:step] }
        assert_equal 2, warnings.size
      end

      test "warns about workflow complexity" do
        steps = (1..25).map { |i| "  - step_#{i}" }.join("\n")
        complex_yaml = <<~YAML
          name: Complex Workflow
          tools: []
          steps:
          #{steps}
        YAML

        validator = ComprehensiveValidator.new(complex_yaml, @workflow_path)
        assert validator.valid?

        warning = validator.warnings.find { |w| w[:type] == :complexity }
        assert warning
        assert_includes warning[:message], "25 steps"
      end

      test "warns about deeply nested conditions" do
        deeply_nested = <<~YAML
          name: Test Workflow
          tools: []
          steps:
            - if: condition1
              then:
                - if: condition2
                  then:
                    - if: condition3
                      then:
                        - if: condition4
                          then:
                            - if: condition5
                              then:
                                - if: condition6
                                  then:
                                    - final_step
        YAML

        validator = ComprehensiveValidator.new(deeply_nested, @workflow_path)
        assert validator.valid?

        warning = validator.warnings.find { |w| w[:type] == :complexity && w[:message].include?("nesting") }
        assert warning
      end

      test "warns about unused tools" do
        yaml_with_unused_tool = <<~YAML
          name: Test Workflow
          tools:
            - Roast::Tools::Bash
            - Roast::Tools::ReadFile
            - Roast::Tools::WriteFile
          steps:
            - first_step
        YAML

        validator = ComprehensiveValidator.new(yaml_with_unused_tool, @workflow_path)
        assert validator.valid?

        # NOTE: This would require more sophisticated analysis to detect tool usage in prompts
        # For now, it's expected to not have warnings
      end

      test "warns about missing error handling" do
        yaml_without_error_handling = <<~YAML
          name: Test Workflow
          tools: []
          steps:
            - risky_step
        YAML

        validator = ComprehensiveValidator.new(yaml_without_error_handling, @workflow_path)
        assert validator.valid?

        warning = validator.warnings.find { |w| w[:type] == :error_handling }
        assert warning
        assert_includes warning[:message], "No error handling"
      end

      test "validates target resource warnings" do
        yaml_with_target = <<~YAML
          name: Test Workflow
          tools: []
          target: "/non/existent/file.txt"
          steps:
            - process_file
        YAML

        validator = ComprehensiveValidator.new(yaml_with_target, @workflow_path)
        assert validator.valid?

        warning = validator.warnings.find { |w| w[:type] == :resource && w[:message].include?("Target file") }
        assert warning
      end

      test "skips target validation for glob patterns" do
        yaml_with_glob = <<~YAML
          name: Test Workflow
          tools: []
          target: "**/*.rb"
          steps:
            - process_files
        YAML

        validator = ComprehensiveValidator.new(yaml_with_glob, @workflow_path)
        assert validator.valid?

        # Should not have target warnings for glob patterns
        target_warnings = validator.warnings.select { |w| w[:type] == :resource && w[:message].include?("Target file") }
        assert_empty target_warnings
      end

      test "validates prompt file existence" do
        yaml_with_steps = <<~YAML
          name: Test Workflow
          tools: []
          steps:
            - missing_prompt_step
        YAML

        validator = ComprehensiveValidator.new(yaml_with_steps, @workflow_path)
        assert validator.valid?

        warning = validator.warnings.find { |w| w[:type] == :resource && w[:message].include?("Prompt file missing") }
        assert warning
        assert_includes warning[:suggestion], "missing_prompt_step/prompt.md"
      end

      test "handles complex workflow structures" do
        complex_yaml = <<~YAML
          name: Complex Workflow
          tools:
            - Roast::Tools::Bash
          steps:
            - pre_process
            - if: "{{ resource.should_process }}"
              then:
                - process_true
              else:
                - process_false
            - case: "{{ resource.action_type }}"
              when:
                action1:
                  - do_action1
                action2:
                  - do_action2
              else:
                - default_action
            - each: items_to_process
              as: item
              steps:
                - process_item
            - repeat:
                steps:
                  - check_status
                until: status_ok
                max_iterations: 5
          post_processing:
            - cleanup
        YAML

        validator = ComprehensiveValidator.new(complex_yaml, @workflow_path)
        assert validator.valid?, "Complex workflow should be valid but got errors: #{validator.errors.inspect}"
      end

      test "handles MCP tool configuration" do
        yaml_with_mcp = <<~YAML
          name: MCP Workflow
          tools:
            - Roast::Tools::Bash
            - mcp_tool:
                url: "http://localhost:3000"
                env:
                  API_KEY: "test"
          steps:
            - use_mcp_tool
        YAML

        validator = ComprehensiveValidator.new(yaml_with_mcp, @workflow_path)
        assert validator.valid?, "Expected MCP workflow to be valid, but got errors: #{validator.errors.inspect}"
      end

      test "provides helpful suggestions for tool names" do
        yaml_with_typo = <<~YAML
          name: Test Workflow
          tools:
            - Roast::Tools::BashCommand
          steps:
            - run_command
        YAML

        validator = ComprehensiveValidator.new(yaml_with_typo, @workflow_path)
        refute validator.valid?

        error = validator.errors.find { |e| e[:tool] == "Roast::Tools::BashCommand" }
        assert error
        assert_includes error[:suggestion], "Roast::Tools::Bash"
      end

      test "handles empty workflow gracefully" do
        validator = ComprehensiveValidator.new("", @workflow_path)
        refute validator.valid?

        error = validator.errors.find { |e| e[:type] == :empty_configuration }
        assert error, "Expected empty_configuration error"
        assert_includes error[:message], "Workflow configuration is empty"
      end

      test "handles nil workflow content" do
        validator = ComprehensiveValidator.new(nil, @workflow_path)
        refute validator.valid?
      end
    end
  end
end
