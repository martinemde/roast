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
        workflow.stubs(:name).returns("test_workflow")

        context = mock
        context.stubs(:workflow).returns(workflow)

        Thread.current[:workflow_context] = context

        # Mock the ContextSummarizer
        mock_summarizer = mock
        mock_summarizer.stubs(:generate_summary).returns("This is a test workflow that has completed step1 and step2.")
        Roast::Tools::ContextSummarizer.stubs(:new).returns(mock_summarizer)

        prompt = "Test prompt"
        result = CodingAgent.send(:prepare_prompt, prompt, true)

        assert_includes result, "<system>"
        assert_includes result, "This is a test workflow that has completed step1 and step2."
        assert_includes result, "</system>"
        assert_includes result, "Test prompt"

        Thread.current[:workflow_context] = nil
      end

      test "generate_context_summary handles missing workflow context" do
        Thread.current[:workflow_context] = nil
        result = CodingAgent.send(:generate_context_summary, "Test prompt")
        assert_nil result
      end

      test "generate_context_summary uses ContextSummarizer" do
        # Create a mock workflow context
        workflow = mock
        context = mock
        context.stubs(:workflow).returns(workflow)

        Thread.current[:workflow_context] = context

        # Mock the ContextSummarizer
        mock_summarizer = mock
        mock_summarizer.expects(:generate_summary).with(context, "Test agent prompt").returns("Generated summary")
        Roast::Tools::ContextSummarizer.stubs(:new).returns(mock_summarizer)

        result = CodingAgent.send(:generate_context_summary, "Test agent prompt")
        assert_equal "Generated summary", result

        Thread.current[:workflow_context] = nil
      end

      test "prepare_prompt returns original prompt when summary is 'No relevant information found in the workflow context.'" do
        # Create a mock workflow context
        workflow = mock
        context = mock
        context.stubs(:workflow).returns(workflow)

        Thread.current[:workflow_context] = context

        # Mock the ContextSummarizer to return "No relevant information found in the workflow context."
        mock_summarizer = mock
        mock_summarizer.stubs(:generate_summary).returns("No relevant information found in the workflow context.")
        Roast::Tools::ContextSummarizer.stubs(:new).returns(mock_summarizer)

        prompt = "Test prompt"
        result = CodingAgent.send(:prepare_prompt, prompt, true)
        assert_equal prompt, result

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
