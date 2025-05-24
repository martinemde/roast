# frozen_string_literal: true

require "test_helper"
require "roast/workflow/workflow_executor"

module Roast
  module Workflow
    class ExitOnErrorTest < Minitest::Test
      include FixtureHelpers

      def setup
        @workflow = BaseWorkflow.new(nil, name: "test_workflow")
        @workflow.output = {}
        @context_path = File.expand_path("../../fixtures/steps", __dir__)
        @config_hash = {}
      end

      def test_command_fails_by_default
        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        assert_raises(WorkflowExecutor::CommandExecutionError) do
          executor.execute_step("$(exit 1)")
        end
      end

      def test_command_continues_with_exit_on_error_false
        @config_hash = {
          "failing_command" => {
            "exit_on_error" => false,
          },
        }

        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Execute a hash step with a failing command
        step = { "failing_command" => "$(exit 42)" }
        executor.send(:execute_hash_step, step)

        # Should not raise and should capture output with exit status
        assert(@workflow.output["failing_command"])
        assert_match(/\[Exit status: 42\]/, @workflow.output["failing_command"])
      end

      def test_command_output_includes_stdout_and_exit_status
        @config_hash = {
          "test_command" => {
            "exit_on_error" => false,
          },
        }

        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Execute a command that outputs text and fails
        step = { "test_command" => "$(echo 'Error: Something went wrong' && exit 1)" }
        executor.send(:execute_hash_step, step)

        output = @workflow.output["test_command"]
        assert_match(/Error: Something went wrong/, output)
        assert_match(/\[Exit status: 1\]/, output)
      end

      def test_command_succeeds_regardless_of_exit_on_error
        @config_hash = {
          "good_command" => {
            "exit_on_error" => false,
          },
        }

        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Execute a successful command
        step = { "good_command" => "$(echo 'Success')" }
        executor.send(:execute_hash_step, step)

        # Should capture output normally without exit status
        assert_equal("Success\n", @workflow.output["good_command"])
        refute_match(/\[Exit status:/, @workflow.output["good_command"])
      end

      def test_strip_and_execute_with_exit_on_error_true
        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Test that it raises on failure when exit_on_error is true (default)
        assert_raises(WorkflowExecutor::CommandExecutionError) do
          executor.send(:strip_and_execute, "$(exit 1)", exit_on_error: true)
        end
      end

      def test_strip_and_execute_with_exit_on_error_false
        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Test that it returns output with exit status when exit_on_error is false
        result = executor.send(:strip_and_execute, "$(echo 'Failed' && exit 5)", exit_on_error: false)

        assert_match(/Failed/, result)
        assert_match(/\[Exit status: 5\]/, result)
      end

      def test_command_exception_handling_with_exit_on_error_false
        @config_hash = {
          "bad_command" => {
            "exit_on_error" => false,
          },
        }

        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Mock a command that throws an exception
        executor.stub(:interpolate, ->(x) { x }) do
          # This should handle exceptions gracefully when exit_on_error is false
          result = executor.send(:strip_and_execute, "$(this_command_does_not_exist_12345)", exit_on_error: false)

          assert_match(/Error executing command:/, result)
          assert_match(/\[Exit status: error\]/, result)
        end
      end

      def test_direct_command_step_always_exits_on_error
        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Direct command steps (without names) should always exit on error
        assert_raises(WorkflowExecutor::CommandExecutionError) do
          executor.send(:execute_string_step, "$(exit 1)")
        end
      end

      def test_warning_logged_when_continuing_after_error
        @config_hash = {
          "warning_test" => {
            "exit_on_error" => false,
          },
        }

        executor = WorkflowExecutor.new(@workflow, @config_hash, @context_path)

        # Capture stderr to verify warning is logged
        _, err = capture_io do
          step = { "warning_test" => "$(exit 3)" }
          executor.send(:execute_hash_step, step)
        end

        assert_match(/WARNING: Command.*exited with non-zero status \(3\), continuing execution/, err)
      end
    end
  end
end
