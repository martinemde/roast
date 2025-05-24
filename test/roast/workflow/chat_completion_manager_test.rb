# frozen_string_literal: true

require "test_helper"
require "roast/workflow/chat_completion_manager"

module Roast
  module Workflow
    class ChatCompletionManagerTest < Minitest::Test
      def setup
        @workflow = mock("workflow")
        @workflow.stubs(:model).returns("gpt-4")
        @workflow.stubs(:openai?).returns(false)
        
        @manager = ChatCompletionManager.new(@workflow)
        @events = []

        # Subscribe to notifications
        @subscription = ActiveSupport::Notifications.subscribe(/roast\.chat_completion\./) do |name, _start, _finish, _id, payload|
          @events << { name: name, payload: payload }
        end
      end

      def teardown
        ActiveSupport::Notifications.unsubscribe(@subscription)
      end

      def test_with_model_temporarily_changes_model
        assert_nil(@manager.current_model)

        @manager.with_model("gpt-4") do
          assert_equal("gpt-4", @manager.current_model)
        end

        assert_nil(@manager.current_model)
      end

      def test_with_model_restores_previous_model_on_error
        @manager.with_model("gpt-3.5") do
          assert_equal("gpt-3.5", @manager.current_model)

          assert_raises(RuntimeError) do
            @manager.with_model("gpt-4") do
              assert_equal("gpt-4", @manager.current_model)
              raise "Error in block"
            end
          end

          # Should restore to gpt-3.5
          assert_equal("gpt-3.5", @manager.current_model)
        end
      end

      def test_model_returns_current_or_workflow_model
        # When no current_model is set, returns workflow model
        assert_equal("gpt-4", @manager.model)
        
        # When current_model is set, returns that instead
        @manager.with_model("gpt-3.5") do
          assert_equal("gpt-3.5", @manager.model)
        end
        
        # Back to workflow model after block
        assert_equal("gpt-4", @manager.model)
      end
      
      def test_openai_delegates_to_workflow
        @workflow.expects(:openai?).returns(true)
        assert(@manager.openai?)
        
        @workflow.expects(:openai?).returns(false)
        refute(@manager.openai?)
      end
    end
  end
end