# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class PromptStepPrintResponseTest < ActiveSupport::TestCase
      test "print_response true appends response to final output" do
        workflow = mock("workflow")
        transcript = []
        workflow.stubs(:transcript).returns(transcript)
        workflow.expects(:append_to_final_output).with("Test response")
        workflow.expects(:chat_completion).with(
          openai: false,
          loop: false, # Changed from true - new BaseStep behavior
          model: "anthropic:claude-opus-4",
          json: false,
          params: {},
        ).returns("Test response") # Return string directly
        workflow.stubs(:openai?).returns(false)
        workflow.stubs(:tools).returns(nil)

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = true

        result = step.call
        assert_equal "Test response", result
        assert_equal 1, transcript.length
        assert_equal({ user: "test_step" }, transcript[0])
      end

      test "print_response false does not append response to final output" do
        workflow = mock("workflow")
        transcript = []
        workflow.stubs(:transcript).returns(transcript)
        workflow.expects(:append_to_final_output).never
        workflow.expects(:chat_completion).with(
          openai: false,
          loop: false, # Changed from true - new BaseStep behavior
          model: "anthropic:claude-opus-4",
          json: false,
          params: {},
        ).returns("Test response") # Return string directly
        workflow.stubs(:openai?).returns(false)
        workflow.stubs(:tools).returns(nil)

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = false

        result = step.call
        assert_equal "Test response", result
      end

      test "parameters are passed correctly from instance variables" do
        workflow = mock("workflow")
        transcript = []
        workflow.stubs(:transcript).returns(transcript)
        workflow.expects(:append_to_final_output).never
        workflow.expects(:chat_completion).with(
          openai: false,
          loop: false,
          model: "anthropic:claude-opus-4",
          json: true,
          params: { temperature: 0.5 },
        ).returns([{ result: "json response" }])
        workflow.stubs(:openai?).returns(false)
        # Since response is array but auto_loop is false, no second call
        workflow.stubs(:tools).returns(nil)

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = false
        step.auto_loop = false
        step.json = true
        step.params = { temperature: 0.5 }

        result = step.call
        assert_equal({ result: "json response" }, result)
      end
    end
  end
end
