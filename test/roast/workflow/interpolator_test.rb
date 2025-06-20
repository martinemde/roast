# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class InterpolatorTest < ActiveSupport::TestCase
      def setup
        @context = Object.new
        @interpolator = Interpolator.new(@context)
      end

      def test_returns_text_without_interpolation_markers
        assert_equal("plain text", @interpolator.interpolate("plain text"))
      end

      def test_returns_non_string_values_unchanged
        assert_equal(123, @interpolator.interpolate(123))
        assert_nil(@interpolator.interpolate(nil))
        assert_equal([:a, :b], @interpolator.interpolate([:a, :b]))
      end

      def test_interpolates_simple_variable
        @context.instance_variable_set(:@file, "test.rb")
        @context.define_singleton_method(:file) { @file }

        result = @interpolator.interpolate("{{file}}")
        assert_equal("test.rb", result)
      end

      def test_interpolates_variable_with_surrounding_text
        @context.instance_variable_set(:@file, "test.rb")
        @context.define_singleton_method(:file) { @file }

        result = @interpolator.interpolate("Process {{file}} with rubocop")
        assert_equal("Process test.rb with rubocop", result)
      end

      def test_interpolates_multiple_variables
        @context.instance_variable_set(:@file, "test.rb")
        @context.instance_variable_set(:@line, 42)
        @context.define_singleton_method(:file) { @file }
        @context.define_singleton_method(:line) { @line }

        result = @interpolator.interpolate("{{file}}:{{line}}")
        assert_equal("test.rb:42", result)
      end

      def test_interpolates_complex_expressions
        @context.instance_variable_set(:@output, { "previous_step" => "result" })
        @context.define_singleton_method(:output) { @output }

        result = @interpolator.interpolate("Using {{output['previous_step']}}")
        assert_equal("Using result", result)
      end

      def test_preserves_expression_on_error
        result = @interpolator.interpolate("Process {{unknown_var}}")
        assert_equal("Process {{unknown_var}}", result)
      end

      def test_logs_error_for_failed_interpolation
        logger = mock("Logger")
        interpolator = Interpolator.new(@context, logger: logger)

        logger.expects(:error) do |msg|
          msg.include?("Error interpolating {{unknown}}:") &&
            msg.include?("undefined local variable or method") &&
            msg.include?("This variable is not defined in the workflow context.")
        end

        interpolator.interpolate("{{unknown}}")
      end

      def test_handles_nested_braces_correctly
        @context.instance_variable_set(:@data, { key: "value" })
        @context.define_singleton_method(:data) { @data }

        result = @interpolator.interpolate("{{data[:key]}}")
        assert_equal("value", result)
      end

      # Tests for shell command backtick escaping
      def test_detects_shell_commands
        shell_command = "$(echo 'test')"
        non_shell_command = "echo 'test'"

        # We can't directly test the private detection logic, but we can test the behavior
        @context.instance_variable_set(:@content, "has `backticks`")
        @context.define_singleton_method(:content) { @content }

        # Shell command should escape backticks
        shell_result = @interpolator.interpolate("$(echo '{{content}}')")
        assert_equal("$(echo 'has \\`backticks\\`')", shell_result)

        # Non-shell command should not escape backticks
        non_shell_result = @interpolator.interpolate("Regular text with {{content}}")
        assert_equal("Regular text with has `backticks`", non_shell_result)
      end

      def test_escapes_backticks_in_shell_commands
        @context.instance_variable_set(:@output, { "step" => "Use `code` here" })
        @context.define_singleton_method(:output) { @output }

        result = @interpolator.interpolate("$(echo '{{output['step']}}')")
        assert_equal("$(echo 'Use \\`code\\` here')", result)
      end

      def test_escapes_multiple_backticks_in_shell_commands
        @context.instance_variable_set(:@content, "`first` and `second` and `third`")
        @context.define_singleton_method(:content) { @content }

        result = @interpolator.interpolate("$(echo '{{content}}')")
        assert_equal("$(echo '\\`first\\` and \\`second\\` and \\`third\\`')", result)
      end

      def test_escapes_backticks_in_double_quoted_shell_commands
        @context.instance_variable_set(:@message, "Run `ls -la` command")
        @context.define_singleton_method(:message) { @message }

        result = @interpolator.interpolate('$(echo "{{message}}")')
        assert_equal('$(echo "Run \\`ls -la\\` command")', result)
      end

      def test_does_not_escape_backticks_in_non_shell_contexts
        @context.instance_variable_set(:@code, "`console.log('hello')`")
        @context.define_singleton_method(:code) { @code }

        # Regular interpolation should preserve backticks
        result = @interpolator.interpolate("Here is some code: {{code}}")
        assert_equal("Here is some code: `console.log('hello')`", result)

        # Markdown context should preserve backticks
        result = @interpolator.interpolate("Use {{code}} in your script")
        assert_equal("Use `console.log('hello')` in your script", result)
      end

      def test_handles_empty_backticks_in_shell_commands
        @context.instance_variable_set(:@empty_code, "``empty``")
        @context.define_singleton_method(:empty_code) { @empty_code }

        result = @interpolator.interpolate("$(echo '{{empty_code}}')")
        assert_equal("$(echo '\\`\\`empty\\`\\`')", result)
      end

      def test_handles_mixed_content_with_backticks_in_shell_commands
        @context.instance_variable_set(:@mixed, "Text with `code` and normal text")
        @context.define_singleton_method(:mixed) { @mixed }

        result = @interpolator.interpolate("$(echo '{{mixed}}')")
        assert_equal("$(echo 'Text with \\`code\\` and normal text')", result)
      end

      def test_shell_command_detection_edge_cases
        @context.instance_variable_set(:@content, "has `backticks`")
        @context.define_singleton_method(:content) { @content }

        # Should detect shell command with spaces
        result = @interpolator.interpolate("  $(echo '{{content}}')  ")
        assert_equal("  $(echo 'has \\`backticks\\`')  ", result)

        # Should not detect partial shell syntax
        result = @interpolator.interpolate("$(incomplete command {{content}}")
        assert_equal("$(incomplete command has `backticks`", result)

        # Should not detect if missing opening
        result = @interpolator.interpolate("echo '{{content}}')")
        assert_equal("echo 'has `backticks`')", result)
      end

      def test_complex_shell_command_with_backticks
        @context.instance_variable_set(:@output, {
          "analysis" => "Found issues in `src/main.js` and `test/spec.js`",
        })
        @context.define_singleton_method(:output) { @output }

        result = @interpolator.interpolate("$(echo \"Analysis: {{output['analysis']}}\")")
        assert_equal("$(echo \"Analysis: Found issues in \\`src/main.js\\` and \\`test/spec.js\\`\")", result)
      end

      def test_nested_shell_commands_with_backticks
        @context.instance_variable_set(:@cmd, "grep `pattern`")
        @context.define_singleton_method(:cmd) { @cmd }

        # Outer shell command should escape backticks in the inner content
        result = @interpolator.interpolate("$(bash -c '{{cmd}}')")
        assert_equal("$(bash -c 'grep \\`pattern\\`')", result)
      end
    end
  end
end
