# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class MetadataIntegrationTest < ActiveSupport::TestCase
      test "metadata flows through workflow execution and state management" do
        # Create workflow
        workflow = BaseWorkflow.new

        # Simulate step execution with metadata
        step_name = "analyze_code"
        step_result = "Found 3 issues"

        # Store step result in output
        workflow.output[step_name] = step_result

        # Store metadata separately
        workflow.metadata_manager.store(step_name, "session_id", "test-session-123")
        workflow.metadata_manager.store(step_name, "duration_ms", 1234)
        workflow.metadata_manager.store(step_name, "tokens_used", 500)

        # Create state manager
        state_repository = mock("state_repository")
        state_manager = StateManager.new(workflow, state_repository: state_repository)

        # Expect state save with metadata
        expected_state_data = {
          step_name: step_name,
          order: 0,
          transcript: [],
          output: { step_name => step_result },
          metadata: {
            step_name => {
              "session_id" => "test-session-123",
              "duration_ms" => 1234,
              "tokens_used" => 500,
            },
          },
          final_output: [],
          execution_order: [step_name],
        }

        state_repository.expects(:save_state).with(workflow, step_name, expected_state_data)

        # Save state
        state_manager.save_state(step_name, step_result)
      end

      test "metadata restored correctly during replay" do
        # Create workflow
        workflow = BaseWorkflow.new

        # Create state data with metadata
        state_data = {
          output: { "step1" => "output1", "step2" => "output2" },
          metadata: {
            "step1" => { "session_id" => "session-1", "duration" => 100 },
            "step2" => { "session_id" => "session-2", "duration" => 200 },
          },
          transcript: [],
          final_output: [],
        }

        # Create replay handler
        state_repository = mock("state_repository")
        replay_handler = ReplayHandler.new(workflow, state_repository: state_repository)

        # Restore state
        replay_handler.send(:restore_workflow_state, state_data)

        # Verify output restored
        assert_equal "output1", workflow.output["step1"]
        assert_equal "output2", workflow.output["step2"]

        # Verify metadata restored separately
        assert_equal "session-1", workflow.metadata["step1"]["session_id"]
        assert_equal 100, workflow.metadata["step1"]["duration"]
        assert_equal "session-2", workflow.metadata["step2"]["session_id"]
        assert_equal 200, workflow.metadata["step2"]["duration"]

        # Verify they remain separate
        workflow.output["step1"] = "modified"
        assert_equal "modified", workflow.output["step1"]
        assert_equal "session-1", workflow.metadata["step1"]["session_id"]
      end

      test "metadata manager methods accessible through workflow" do
        workflow = BaseWorkflow.new

        # Store metadata using convenience methods
        workflow.metadata_manager.store("process_data", "start_time", Time.now.to_i)
        workflow.metadata_manager.store("process_data", "input_size", 1024)

        # Retrieve using different access patterns
        assert workflow.metadata_manager.has_metadata?("process_data")
        assert_equal 1024, workflow.metadata_manager.retrieve("process_data", "input_size")

        # Access through delegated metadata method
        assert_equal 1024, workflow.metadata["process_data"]["input_size"]
        assert_equal 1024, workflow.metadata.process_data.input_size

        # Get all metadata for step
        step_metadata = workflow.metadata_manager.for_step("process_data")
        assert_includes step_metadata.keys, "start_time"
        assert_includes step_metadata.keys, "input_size"
      end
    end
  end
end
