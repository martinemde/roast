# frozen_string_literal: true

require "test_helper"
require "roast/workflow/chat_completion_manager"

module Roast
  module Workflow
    class ChatCompletionManagerTest < Minitest::Test
      def setup
        @workflow = mock("workflow")
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

      def test_chat_completion_calls_workflow_and_instruments
        params = { messages: [{ role: "user", content: "Hello" }], model: "gpt-4" }
        expected_result = "AI response"

        @workflow.expects(:super_chat_completion).with(messages: params[:messages]).returns(expected_result)

        result = @manager.chat_completion(**params)

        assert_equal(expected_result, result)
        assert_equal(2, @events.size)

        start_event = @events.find { |e| e[:name] == "roast.chat_completion.start" }
        assert_equal("gpt-4", start_event[:payload][:model])
        assert_equal(params[:messages], start_event[:payload][:parameters][:messages])

        complete_event = @events.find { |e| e[:name] == "roast.chat_completion.complete" }
        assert(complete_event[:payload][:success])
        assert_equal("gpt-4", complete_event[:payload][:model])
        assert_kind_of(Float, complete_event[:payload][:execution_time])
        assert_equal(expected_result.length, complete_event[:payload][:response_size])
      end

      def test_chat_completion_instruments_errors
        params = { messages: [{ role: "user", content: "Hello" }], model: "gpt-4" }
        error = StandardError.new("API Error")

        @workflow.expects(:super_chat_completion).raises(error)

        assert_raises(StandardError) do
          @manager.chat_completion(**params)
        end

        error_event = @events.find { |e| e[:name] == "roast.chat_completion.error" }
        assert_equal("StandardError", error_event[:payload][:error])
        assert_equal("API Error", error_event[:payload][:message])
        assert_equal("gpt-4", error_event[:payload][:model])
        assert_kind_of(Float, error_event[:payload][:execution_time])
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

      def test_excludes_openai_and_model_from_parameters
        params = {
          messages: [{ role: "user", content: "Hello" }],
          model: "gpt-4",
          openai: "api_instance",
          temperature: 0.7,
        }

        @workflow.expects(:super_chat_completion).with(
          messages: params[:messages],
          temperature: params[:temperature],
        ).returns("response")

        @manager.chat_completion(**params)

        start_event = @events.find { |e| e[:name] == "roast.chat_completion.start" }
        assert_equal({ messages: params[:messages], temperature: params[:temperature] }, start_event[:payload][:parameters])
        refute(start_event[:payload][:parameters].key?(:model))
        refute(start_event[:payload][:parameters].key?(:openai))
      end
    end
  end
end
