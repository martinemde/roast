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
      end
      
      test "print_response with tool calls displays tool results instead of final AI response" do
        workflow = MockWorkflowWithTools.new
        
        # Mock chat_completion to return an array (simulating tool call results)
        workflow.stub :chat_completion, ["Tool result 1", "Tool result 2"] do
          step = PromptStep.new(workflow, name: "test_step")
          step.print_response = true
          step.auto_loop = true
          
          result = step.call
          
          # The bug: tool results are joined and displayed
          assert_equal "Tool result 1\nTool result 2", result
          assert_equal 1, workflow.appended_output.size
          assert_equal "Tool result 1\nTool result 2", workflow.appended_output.first
        end
      end
      
      test "print_response false with tool calls does not append output" do
        workflow = MockWorkflowWithTools.new
        
        workflow.stub :chat_completion, ["Tool result 1", "Tool result 2"] do
          step = PromptStep.new(workflow, name: "test_step")
          step.print_response = false
          
          result = step.call
          
          assert_equal "Tool result 1\nTool result 2", result
          assert_empty workflow.appended_output
        end
      end
      
      test "print_response with string response works correctly" do
        workflow = MockWorkflowWithTools.new
        
        workflow.stub :chat_completion, "This is the final AI response" do
          step = PromptStep.new(workflow, name: "test_step")
          step.print_response = true
          
          result = step.call
          
          assert_equal "This is the final AI response", result
          assert_equal 1, workflow.appended_output.size
          assert_equal "This is the final AI response", workflow.appended_output.first
        end
      end
    end
  end
end