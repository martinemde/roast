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

      def test_chat_completion_module_not_included_in_base_workflow
        workflow = TestWorkflow.new(nil, name: "test", configuration: MockConfiguration.new)
        
        # Verify that BaseWorkflow doesn't include Raix::ChatCompletion methods directly
        refute(workflow.class.included_modules.include?(Raix::ChatCompletion))
      end

      def test_chat_completion_delegates_to_manager
        workflow = TestWorkflow.new(nil, name: "test", configuration: MockConfiguration.new)
        
        # Mock the chat completion manager
        manager = workflow.instance_variable_get(:@chat_completion_manager)
        manager.expects(:chat_completion).with(messages: ["test"]).returns("result")
        
        result = workflow.chat_completion(messages: ["test"])
        assert_equal("result", result)
      end

      def test_chat_completion_manager_includes_raix_module
        workflow = TestWorkflow.new(nil, name: "test", configuration: MockConfiguration.new)
        manager = workflow.instance_variable_get(:@chat_completion_manager)
        
        assert(manager.class.included_modules.include?(Raix::ChatCompletion))
      end
    end
  end
end