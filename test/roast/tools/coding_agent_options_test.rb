# frozen_string_literal: true

require "test_helper"

module Roast
  module Tools
    class CodingAgentOptionsTest < ActiveSupport::TestCase
      def setup
        @original_env = ENV["CLAUDE_CODE_COMMAND"]
        ENV["CLAUDE_CODE_COMMAND"] = "claude -p --verbose --output-format stream-json"
        CodingAgent.configured_command = nil
      end

      def teardown
        ENV["CLAUDE_CODE_COMMAND"] = @original_env
        CodingAgent.configured_command = nil
      end

      test "build_command adds --continue flag when continue is true" do
        base_command = "claude -p --verbose --output-format stream-json"
        result = CodingAgent.send(:build_command, base_command, continue: true)
        assert_equal "claude --continue -p --verbose --output-format stream-json", result
      end

      test "build_command returns base command when continue is false" do
        base_command = "claude -p --verbose --output-format stream-json"
        result = CodingAgent.send(:build_command, base_command, continue: false)
        assert_equal base_command, result
      end

      test "build_command handles non-standard commands" do
        base_command = "custom-claude-wrapper --some-flag"
        result = CodingAgent.send(:build_command, base_command, continue: true)
        assert_equal "custom-claude-wrapper --some-flag --continue", result
      end

      test "prepare_prompt returns original prompt when include_context_summary is false" do
        prompt = "Test prompt"
        result = CodingAgent.send(:prepare_prompt, prompt, false)
        assert_equal prompt, result
      end

      test "prepare_prompt adds context summary when include_context_summary is true" do
        # Create a mock workflow context
        workflow = mock
        workflow.stubs(:config).returns({ "description" => "Test workflow" })
        workflow.stubs(:output).returns({ "step1" => "output1", "step2" => "output2" })

        context = mock
        context.stubs(:workflow).returns(workflow)

        Thread.current[:workflow_context] = context

        prompt = "Test prompt"
        result = CodingAgent.send(:prepare_prompt, prompt, true)

        assert_includes result, "<system>"
        assert_includes result, "Workflow: Test workflow"
        assert_includes result, "Previous step outputs:"
        assert_includes result, "- step1: output1"
        assert_includes result, "- step2: output2"
        assert_includes result, "Working directory:"
        assert_includes result, "</system>"
        assert_includes result, "Test prompt"

        Thread.current[:workflow_context] = nil
      end

      test "generate_context_summary handles missing workflow context" do
        Thread.current[:workflow_context] = nil
        result = CodingAgent.send(:generate_context_summary)
        assert_nil result
      end

      test "generate_context_summary truncates long outputs" do
        # Create a mock workflow with a long output
        long_output = "x" * 300

        workflow = mock
        workflow.stubs(:config).returns({})
        workflow.stubs(:output).returns({ "long_step" => long_output })

        context = mock
        context.stubs(:workflow).returns(workflow)

        Thread.current[:workflow_context] = context

        result = CodingAgent.send(:generate_context_summary)

        # Check that the output was truncated (201 chars = 200 + "...")
        assert result.include?("- long_step:")
        assert result.include?("...")
        # Verify the truncated output is approximately the right length
        long_step_line = result.lines.find { |line| line.include?("- long_step:") }
        output_part = long_step_line.split(": ", 2).last.chomp
        assert_equal 204, output_part.length # 200 chars + "..."
        refute_includes result, "x" * 300

        Thread.current[:workflow_context] = nil
      end

      test "call method passes options correctly" do
        # Mock the run_claude_code method to verify it receives the correct options
        CodingAgent.expects(:run_claude_code).with(
          "Test prompt",
          include_context_summary: true,
          continue: true,
        ).returns("Success")

        result = CodingAgent.call("Test prompt", include_context_summary: true, continue: true)
        assert_equal "Success", result
      end
    end
  end
end
