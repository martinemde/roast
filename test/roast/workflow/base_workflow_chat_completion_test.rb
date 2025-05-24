# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class BaseWorkflowChatCompletionTest < Minitest::Test
      class TestWorkflow < BaseWorkflow
        # Override to avoid loading prompt files
        def read_sidecar_prompt
          nil
        end
      end

      class MockConfiguration
        def api_provider
          "openai"
        end

        def openai?
          true
        end
      end

      def test_original_chat_completion_method_exists
        workflow = TestWorkflow.new(nil, name: "test", configuration: MockConfiguration.new)
        
        # Verify that original_chat_completion method exists and is private
        assert(workflow.private_methods.include?(:original_chat_completion))
      end

      def test_chat_completion_delegates_to_manager
        workflow = TestWorkflow.new(nil, name: "test", configuration: MockConfiguration.new)
        
        # Mock the chat completion manager
        manager = workflow.instance_variable_get(:@chat_completion_manager)
        manager.expects(:chat_completion).with(messages: ["test"]).returns("result")
        
        result = workflow.chat_completion(messages: ["test"])
        assert_equal("result", result)
      end

      def test_original_chat_completion_constant_is_defined
        assert(BaseWorkflow.const_defined?(:ORIGINAL_CHAT_COMPLETION))
        assert_kind_of(UnboundMethod, BaseWorkflow::ORIGINAL_CHAT_COMPLETION)
      end
    end
  end
end