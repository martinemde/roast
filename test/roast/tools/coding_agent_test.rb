# frozen_string_literal: true

require "test_helper"

module Roast
  module Tools
    class CodingAgentTest < ActiveSupport::TestCase
      class DummyBaseClass
        class << self
          attr_accessor :registered_functions

          def function(name, description, **params, &block)
            @registered_functions ||= {}
            @registered_functions[name] = {
              description: description,
              params: params,
              block: block,
            }
          end
        end
      end

      setup do
        # Reset the configured command before each test
        Roast::Tools::CodingAgent.configured_command = nil
      end

      test "uses default command when no configuration is provided" do
        # Mock Open3.capture3 to prevent actual command execution
        mock_stdout = "AI response"
        mock_stderr = ""
        mock_status = mock
        mock_status.expects(:success?).returns(true)

        Open3.expects(:capture3).with { |cmd| cmd =~ /cat .* \| claude -p$/ }.returns([mock_stdout, mock_stderr, mock_status])

        result = Roast::Tools::CodingAgent.call("Test prompt")
        assert_equal "AI response", result
      end

      test "uses environment variable when set" do
        original_env = ENV["CLAUDE_CODE_COMMAND"]
        ENV["CLAUDE_CODE_COMMAND"] = "claude --model opus"

        # Mock Open3.capture3
        mock_stdout = "AI response"
        mock_stderr = ""
        mock_status = mock
        mock_status.expects(:success?).returns(true)

        Open3.expects(:capture3).with { |cmd| cmd =~ /cat .* \| claude --model opus$/ }.returns([mock_stdout, mock_stderr, mock_status])

        result = Roast::Tools::CodingAgent.call("Test prompt")
        assert_equal("AI response", result)
      ensure
        ENV["CLAUDE_CODE_COMMAND"] = original_env
      end

      test "post_configuration_setup sets configured command" do
        config = { "coding_agent_command" => "claude --model opus -p --allowedTools \"Bash, Glob\"" }
        Roast::Tools::CodingAgent.post_configuration_setup(DummyBaseClass, config)

        assert_equal "claude --model opus -p --allowedTools \"Bash, Glob\"", Roast::Tools::CodingAgent.configured_command
      end

      test "uses configured command from post_configuration_setup" do
        config = { "coding_agent_command" => "claude --model opus -p --allowedTools \"Bash, Batch, Glob, Grep, LS, Read\"" }
        Roast::Tools::CodingAgent.post_configuration_setup(DummyBaseClass, config)

        # Mock Open3.capture3
        mock_stdout = "AI response with custom config"
        mock_stderr = ""
        mock_status = mock
        mock_status.expects(:success?).returns(true)

        expected_command = /cat .* \| claude --model opus -p --allowedTools "Bash, Batch, Glob, Grep, LS, Read"$/
        Open3.expects(:capture3).with { |cmd| cmd =~ expected_command }.returns([mock_stdout, mock_stderr, mock_status])

        result = Roast::Tools::CodingAgent.call("Test prompt")
        assert_equal "AI response with custom config", result
      end

      test "configuration takes precedence over environment variable" do
        original_env = ENV["CLAUDE_CODE_COMMAND"]
        ENV["CLAUDE_CODE_COMMAND"] = "claude --model haiku"

        config = { "coding_agent_command" => "claude --model opus" }
        Roast::Tools::CodingAgent.post_configuration_setup(DummyBaseClass, config)

        # Mock Open3.capture3
        mock_stdout = "AI response"
        mock_stderr = ""
        mock_status = mock
        mock_status.expects(:success?).returns(true)

        # Should use configured command, not environment variable
        Open3.expects(:capture3).with { |cmd| cmd =~ /cat .* \| claude --model opus$/ }.returns([mock_stdout, mock_stderr, mock_status])

        result = Roast::Tools::CodingAgent.call("Test prompt")
        assert_equal("AI response", result)
      ensure
        ENV["CLAUDE_CODE_COMMAND"] = original_env
      end

      test "handles command execution errors gracefully" do
        mock_stdout = ""
        mock_stderr = "Command not found: claude"
        mock_status = mock
        mock_status.expects(:success?).returns(false)

        Open3.expects(:capture3).returns([mock_stdout, mock_stderr, mock_status])

        result = Roast::Tools::CodingAgent.call("Test prompt")
        assert_equal "Error running ClaudeCode: Command not found: claude", result
      end

      test "cleans up temporary files even on error" do
        # Force an error during command execution
        Open3.expects(:capture3).raises(StandardError, "Execution failed")

        # Track temp file creation and deletion
        tempfile_deleted = false

        Tempfile.any_instance.stubs(:write)
        Tempfile.any_instance.stubs(:close)
        Tempfile.any_instance.stubs(:path).returns("/tmp/test_file.txt")

        # Monitor tempfile lifecycle
        Tempfile.any_instance.expects(:unlink).at_least_once.with do
          tempfile_deleted = true
          true
        end

        result = Roast::Tools::CodingAgent.call("Test prompt")

        assert_match(/Error running CodingAgent/, result)
        assert tempfile_deleted, "Temporary file should be cleaned up even on error"
      end

      test "included method registers coding_agent function" do
        DummyBaseClass.registered_functions = {}
        Roast::Tools::CodingAgent.included(DummyBaseClass)

        assert DummyBaseClass.registered_functions.key?(:coding_agent)

        function_def = DummyBaseClass.registered_functions[:coding_agent]
        assert_equal "AI-powered coding agent that runs Claude Code CLI with the given prompt", function_def[:description]
        assert_equal "string", function_def[:params][:prompt][:type]
        assert_equal "The prompt to send to Claude Code", function_def[:params][:prompt][:description]
      end
    end
  end
end
