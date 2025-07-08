# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class StateManagerMetadataTest < ActiveSupport::TestCase
      def setup
        @workflow = mock("workflow")
        @workflow.stubs(:session_name).returns("test_session")
        @state_repository = mock("state_repository")
        @state_manager = StateManager.new(@workflow, state_repository: @state_repository)
      end

      test "build_state_data includes metadata" do
        # Setup workflow mocks with metadata
        @workflow.stubs(:output).returns({ "step1" => "output1" })
        @workflow.stubs(:metadata).returns({ "step1" => { "session_id" => "abc123" } })
        @workflow.stubs(:transcript).returns([{ role: "user", content: "test" }])
        @workflow.stubs(:final_output).returns(["final output"])

        state_data = @state_manager.send(:build_state_data, "step1", "result")

        assert_equal "step1", state_data[:step_name]
        assert_equal({ "step1" => "output1" }, state_data[:output])
        assert_equal({ "step1" => { "session_id" => "abc123" } }, state_data[:metadata])
        assert_equal([{ role: "user", content: "test" }], state_data[:transcript])
        assert_equal(["final output"], state_data[:final_output])
        assert_equal(["step1"], state_data[:execution_order])
      end

      test "extract_metadata returns empty hash when workflow has no metadata method" do
        workflow_without_metadata = mock("workflow")
        state_manager = StateManager.new(workflow_without_metadata, state_repository: @state_repository)

        result = state_manager.send(:extract_metadata)
        assert_equal({}, result)
      end

      test "extract_metadata returns cloned metadata when available" do
        original_metadata = { "step1" => { "session_id" => "xyz789" } }
        @workflow.stubs(:metadata).returns(original_metadata)

        result = @state_manager.send(:extract_metadata)

        # Verify it's a clone
        assert_equal original_metadata, result
        refute_same original_metadata, result
      end

      test "save_state includes metadata in state data" do
        # Setup workflow with all necessary methods
        @workflow.stubs(:output).returns({ "step1" => "output1" })
        @workflow.stubs(:metadata).returns({ "step1" => { "session_id" => "test123" } })
        @workflow.stubs(:transcript).returns([])
        @workflow.stubs(:final_output).returns([])

        expected_state_data = {
          step_name: "step1",
          order: 0,
          transcript: [],
          output: { "step1" => "output1" },
          metadata: { "step1" => { "session_id" => "test123" } },
          final_output: [],
          execution_order: ["step1"],
        }

        @state_repository.expects(:save_state).with(@workflow, "step1", expected_state_data)

        @state_manager.save_state("step1", "result")
      end
    end
  end
end
