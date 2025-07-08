# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class ReplayHandlerMetadataTest < ActiveSupport::TestCase
      def setup
        @workflow = mock("workflow")
        @state_repository = mock("state_repository")
        @replay_handler = ReplayHandler.new(@workflow, state_repository: @state_repository)
      end

      test "restore_workflow_state restores metadata" do
        state_data = {
          output: { "step1" => "output1", "step2" => "output2" },
          metadata: { "step1" => { "session_id" => "abc123" }, "step2" => { "session_id" => "def456" } },
          transcript: [{ role: "user", content: "test" }],
          final_output: ["final"],
        }

        # Setup expectations
        @workflow.expects(:output=).with({ "step1" => "output1", "step2" => "output2" })
        @workflow.expects(:metadata=).with({ "step1" => { "session_id" => "abc123" }, "step2" => { "session_id" => "def456" } })

        # Create a mock transcript that responds to both respond_to? checks and methods
        transcript_mock = mock("transcript")
        transcript_mock.stubs(:respond_to?).with(:clear).returns(true)
        transcript_mock.stubs(:respond_to?).with(:<<).returns(true)
        transcript_mock.expects(:clear).once
        transcript_mock.expects(:<<).with({ role: "user", content: "test" }).once
        @workflow.stubs(:transcript).returns(transcript_mock)

        @workflow.expects(:final_output=).with(["final"])

        @replay_handler.send(:restore_workflow_state, state_data)
      end

      test "restore_metadata sets metadata when workflow supports it" do
        state_data = {
          metadata: { "step1" => { "session_id" => "test123", "duration" => 1234 } },
        }

        @workflow.expects(:metadata=).with({ "step1" => { "session_id" => "test123", "duration" => 1234 } })

        @replay_handler.send(:restore_metadata, state_data)
      end

      test "restore_metadata skips when state has no metadata" do
        state_data = {
          output: { "step1" => "output1" },
        }

        @workflow.expects(:metadata=).never

        @replay_handler.send(:restore_metadata, state_data)
      end

      test "restore_metadata skips when workflow doesn't support metadata" do
        state_data = {
          metadata: { "step1" => { "session_id" => "test123" } },
        }

        workflow_without_metadata = mock("workflow")
        workflow_without_metadata.stubs(:respond_to?).with(:metadata=).returns(false)

        replay_handler = ReplayHandler.new(workflow_without_metadata, state_repository: @state_repository)

        # Should not raise an error
        assert_nothing_raised do
          replay_handler.send(:restore_metadata, state_data)
        end
      end

      test "load_state_and_restore includes metadata restoration" do
        state_data = {
          output: { "step1" => "output1" },
          metadata: { "step1" => { "session_id" => "xyz789" } },
          transcript: [],
          final_output: [],
        }

        @state_repository.expects(:load_state_before_step).with(@workflow, "step2").returns(state_data)
        @workflow.expects(:output=).with({ "step1" => "output1" })
        @workflow.expects(:metadata=).with({ "step1" => { "session_id" => "xyz789" } })

        # Create a mock transcript that responds to both respond_to? checks and methods
        transcript_mock = mock("transcript")
        transcript_mock.stubs(:respond_to?).with(:clear).returns(true)
        transcript_mock.stubs(:respond_to?).with(:<<).returns(true)
        transcript_mock.expects(:clear).once
        # No << calls expected since transcript is empty
        @workflow.stubs(:transcript).returns(transcript_mock)

        @workflow.expects(:final_output=).with([])

        result = @replay_handler.load_state_and_restore("step2")
        assert_equal state_data, result
      end
    end
  end
end
