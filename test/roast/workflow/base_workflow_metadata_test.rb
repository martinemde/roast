# frozen_string_literal: true

require "test_helper"

class RoastWorkflowBaseWorkflowMetadataTest < ActiveSupport::TestCase
  test "workflow has metadata attribute initialized with MetadataManager" do
    workflow = Roast::Workflow::BaseWorkflow.new

    assert_respond_to workflow, :metadata
    assert_respond_to workflow, :metadata=
    assert_kind_of Roast::Workflow::DotAccessHash, workflow.metadata
  end

  test "metadata can store and retrieve values by step name" do
    workflow = Roast::Workflow::BaseWorkflow.new

    # Store metadata for a step
    workflow.metadata["step1"] = { "session_id" => "abc123", "duration" => 1234 }

    # Retrieve metadata
    assert_equal "abc123", workflow.metadata["step1"]["session_id"]
    assert_equal 1234, workflow.metadata["step1"]["duration"]

    # Test dot notation access
    assert_equal "abc123", workflow.metadata.step1.session_id
    assert_equal 1234, workflow.metadata.step1.duration
  end

  test "metadata is separate from output" do
    workflow = Roast::Workflow::BaseWorkflow.new

    # Set output and metadata for the same step
    workflow.output["step1"] = "This is the output"
    workflow.metadata["step1"] = { "session_id" => "xyz789" }

    # Verify they are separate
    assert_equal "This is the output", workflow.output["step1"]
    assert_equal({ "session_id" => "xyz789" }, workflow.metadata["step1"].to_h)

    # Modifying one doesn't affect the other
    workflow.output["step1"] = "Modified output"
    assert_equal "Modified output", workflow.output["step1"]
    assert_equal "xyz789", workflow.metadata["step1"]["session_id"]
  end

  test "metadata manager is exposed for state management" do
    workflow = Roast::Workflow::BaseWorkflow.new

    assert_respond_to workflow, :metadata_manager
    assert_kind_of Roast::Workflow::MetadataManager, workflow.metadata_manager

    # Verify it's a different instance than output_manager
    refute_equal workflow.output_manager, workflow.metadata_manager
  end

  test "metadata works with indifferent access" do
    workflow = Roast::Workflow::BaseWorkflow.new

    # Set with string key
    workflow.metadata["step1"] = { "session_id" => "test123" }

    # Access with symbol key
    assert_equal "test123", workflow.metadata[:step1][:session_id]

    # Set with symbol key
    workflow.metadata[:step2] = { session_id: "test456" }

    # Access with string key
    assert_equal "test456", workflow.metadata["step2"]["session_id"]
  end

  test "metadata supports nested structures" do
    workflow = Roast::Workflow::BaseWorkflow.new

    workflow.metadata["complex_step"] = {
      "session_info" => {
        "id" => "nested123",
        "timestamp" => Time.now.to_i,
        "config" => {
          "model" => "opus",
          "temperature" => 0.7,
        },
      },
      "metrics" => {
        "tokens_used" => 1500,
        "duration_ms" => 2345,
      },
    }

    # Test nested access
    assert_equal "nested123", workflow.metadata.complex_step.session_info.id
    assert_equal "opus", workflow.metadata.complex_step.session_info.config.model
    assert_equal 1500, workflow.metadata.complex_step.metrics.tokens_used
  end
end
