# frozen_string_literal: true

require "test_helper"

class CodingAgentResumeTest < ActiveSupport::TestCase
  def setup
    @original_env = ENV["CLAUDE_CODE_COMMAND"]
    @test_session_id = "test-session-abc123"
  end

  def teardown
    ENV["CLAUDE_CODE_COMMAND"] = @original_env
    Thread.current[:workflow_context] = nil
    Thread.current[:current_step_name] = nil
  end

  test "coding agent stores session ID in metadata after successful execution" do
    # Mock command to return JSON with session ID
    # Note: The comment with --output-format stream-json tells the agent to expect JSON
    ENV["CLAUDE_CODE_COMMAND"] = "echo '{\"type\":\"result\",\"subtype\":\"success\",\"result\":\"Test result\",\"session_id\":\"#{@test_session_id}\"}' # --output-format stream-json"

    # Create a mock workflow with metadata support
    workflow = mock
    metadata_hash = {}
    workflow.stubs(:metadata).returns(metadata_hash)

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context
    Thread.current[:current_step_name] = "test_step"

    # Execute coding agent
    result = Roast::Tools::CodingAgent.call("Test prompt")

    # Verify result
    assert_equal "Test result", result

    # Verify session ID was stored in metadata
    assert_equal @test_session_id, metadata_hash["test_step"]["session_id"]
  end

  test "coding agent resumes from previous session when resume parameter is provided" do
    # For integration testing, we focus on behavior rather than exact command verification
    # The unit tests already verify the command building logic
    ENV["CLAUDE_CODE_COMMAND"] = "echo '{\"type\":\"result\",\"subtype\":\"success\",\"result\":\"Resumed result\"}' # --output-format stream-json"

    # Create a mock workflow with existing session ID in metadata
    workflow = mock
    workflow.stubs(:metadata).returns({
      "previous_step" => { "session_id" => "existing-session-xyz789" },
    })

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context
    Thread.current[:current_step_name] = "current_step"

    # Verify that logger shows the resume message when session ID is found
    # AND verify the command includes the --resume flag with the session ID
    Roast::Helpers::Logger.stubs(:debug)
    Roast::Helpers::Logger.expects(:debug).with("🤖 Resuming from session ID: existing-session-xyz789 (from step: previous_step)\n").once
    Roast::Helpers::Logger.expects(:debug).with { |msg| msg.include?("--resume existing-session-xyz789") }.once

    # Execute coding agent with resume
    result = Roast::Tools::CodingAgent.call("Resume work", resume: "previous_step")

    # Verify it executed successfully
    assert_equal "Resumed result", result
  end

  test "coding agent validates session ID format before using it" do
    # Use a mock command that would show if the malicious ID got through
    ENV["CLAUDE_CODE_COMMAND"] = "echo 'Should not execute with malicious session ID'"

    # Create a mock workflow with invalid session ID in metadata
    workflow = mock
    workflow.stubs(:metadata).returns({
      "malicious_step" => { "session_id" => "abc; echo rm -rf /" }, # Malicious session ID
    })

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context

    # Attempt to resume with malicious session ID should return error message
    result = Roast::Tools::CodingAgent.call("Test prompt", resume: "malicious_step")

    # The error is caught and returned as a string
    assert_includes result, "Error running CodingAgent: Invalid session ID format"
    # Ensure the command never executed
    refute_includes result, "Should not execute"
  end

  test "coding agent handles missing session ID gracefully when resuming" do
    # Mock command to return success without session ID
    # Note: The comment with --output-format stream-json tells the agent to expect JSON
    ENV["CLAUDE_CODE_COMMAND"] = "echo '{\"type\":\"result\",\"subtype\":\"success\",\"result\":\"Test result\",\"session_id\":\"#{@test_session_id}\"}' # --output-format stream-json"

    # Create a mock workflow without session ID in metadata
    workflow = mock
    workflow.stubs(:metadata).returns({
      "empty_step" => {}, # No session_id
    })

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context
    Thread.current[:current_step_name] = "current_step"

    # Verify warning is logged when no session ID found
    Roast::Helpers::Logger.expects(:warn).with("🤖 No session ID found for step 'empty_step'. Starting fresh session.\n").once

    # Should execute normally without --resume flag
    result = Roast::Tools::CodingAgent.call("Test prompt", resume: "empty_step")

    # Verify it executed without errors
    assert_equal "Test result", result
  end

  test "resume takes precedence over continue when both are specified" do
    # This behavior is thoroughly tested in unit tests
    # For integration test, we verify high-level behavior
    ENV["CLAUDE_CODE_COMMAND"] = "echo '{\"type\":\"result\",\"subtype\":\"success\",\"result\":\"Result\"}' # --output-format stream-json"

    # Create a mock workflow with session ID
    workflow = mock
    workflow.stubs(:metadata).returns({
      "step_with_session" => { "session_id" => "priority-session-123" },
    })

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context

    # Verify the resume debug message is logged (proves resume path was taken)
    # Allow other debug messages but require the specific resume message
    Roast::Helpers::Logger.stubs(:debug)
    Roast::Helpers::Logger.expects(:debug).with("🤖 Resuming from session ID: priority-session-123 (from step: step_with_session)\n").once

    # Execute with both resume and continue
    result = Roast::Tools::CodingAgent.call("Test", resume: "step_with_session", continue: true)

    # Verify successful execution
    assert_equal "Result", result
  end
end
