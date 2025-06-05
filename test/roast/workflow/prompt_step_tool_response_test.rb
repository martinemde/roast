# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class PromptStepToolResponseTest < ActiveSupport::TestCase
      class MockWorkflowWithTools
        include Raix::ChatCompletion
        include Raix::FunctionDispatch

        attr_accessor :call_count, :tools
        attr_reader :appended_output

        function :get_weather, "Get weather", location: { type: "string" } do |args|
          "Sunny and 72°F in #{args[:location]}"
        end

        def initialize
          @transcript = []
          @appended_output = []
          @call_count = 0
          @tools = []
        end

        def openai?
          false
        end

        def append_to_final_output(text)
          @appended_output << text
        end

        def model
          "test-model"
        end

        def chat_completion(**kwargs)
          # Don't call super, return nil to trigger the stub
          nil
        end
      end

      test "print_response with tool calls displays tool results instead of final AI response" do
        workflow = MockWorkflowWithTools.new

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = true

        # Mock chat_completion to return string response
        def workflow.chat_completion(**kwargs)
          "Tool result 1\nTool result 2"
        end

        result = step.call

        # The result should be the assistant response from transcript
        assert_equal "Tool result 1\nTool result 2", result
        assert_equal 1, workflow.appended_output.size
        assert_equal "Tool result 1\nTool result 2", workflow.appended_output.first
      end

      test "print_response false with tool calls does not append output" do
        workflow = MockWorkflowWithTools.new

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = false

        # Mock chat_completion to return string response
        def workflow.chat_completion(**kwargs)
          "Tool result 1\nTool result 2"
        end

        result = step.call

        assert_equal "Tool result 1\nTool result 2", result
        assert_empty workflow.appended_output
      end

      test "print_response with string response works correctly" do
        workflow = MockWorkflowWithTools.new

        step = PromptStep.new(workflow, name: "test_step")
        step.print_response = true

        # Mock chat_completion for string response
        def workflow.chat_completion(**kwargs)
          "This is the final AI response"
        end

        result = step.call

        assert_equal "This is the final AI response", result
        assert_equal 1, workflow.appended_output.size
        assert_equal "This is the final AI response", workflow.appended_output.first
      end
    end
  end
end
