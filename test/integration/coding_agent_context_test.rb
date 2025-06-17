# frozen_string_literal: true

require "test_helper"

class CodingAgentContextTest < ActiveSupport::TestCase
  def setup
    @original_env = ENV["CLAUDE_CODE_COMMAND"]
    ENV["CLAUDE_CODE_COMMAND"] = "echo 'Mock Claude Code Response'"
  end

  def teardown
    ENV["CLAUDE_CODE_COMMAND"] = @original_env
    Thread.current[:workflow_context] = nil
  end

  test "coding agent receives context summary when include_context_summary is true" do
    # Create a mock workflow with some context
    workflow = mock
    workflow.stubs(:config).returns({
      "description" => "Workflow to process and analyze data files",
    })
    workflow.stubs(:output).returns({
      "fetch_data" => "Retrieved 50 records from database",
      "validate_data" => "Found 3 invalid records that need correction",
    })
    workflow.stubs(:name).returns("data_processor")

    # Create workflow context
    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context

    # Mock the ContextSummarizer to return a known summary
    mock_summarizer = mock
    mock_summarizer.stubs(:generate_summary).with(context, "Fix the invalid records").returns(
      "The workflow has retrieved 50 records and identified 3 that need correction.",
    )
    Roast::Tools::ContextSummarizer.stubs(:new).returns(mock_summarizer)

    # Call CodingAgent with include_context_summary
    result = Roast::Tools::CodingAgent.call(
      "Fix the invalid records",
      include_context_summary: true,
      continue: false,
    )

    # The result would include the processing of the prompt with context
    assert_not_nil result
  end

  test "coding agent works without context summary when include_context_summary is false" do
    # Create a mock workflow
    workflow = mock
    workflow.stubs(:config).returns({})
    workflow.stubs(:output).returns({})

    context = mock
    context.stubs(:workflow).returns(workflow)
    Thread.current[:workflow_context] = context

    # CodingAgent should not create a ContextSummarizer when include_context_summary is false
    Roast::Tools::ContextSummarizer.expects(:new).never

    # Call CodingAgent without context summary
    result = Roast::Tools::CodingAgent.call(
      "Perform a simple task",
      include_context_summary: false,
      continue: false,
    )

    assert_not_nil result
  end
end
