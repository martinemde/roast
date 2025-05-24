# frozen_string_literal: true

require "active_support"
require "active_support/notifications"
require "raix/chat_completion"

module Roast
  module Workflow
    # Manages chat completion interactions with instrumentation
    class ChatCompletionManager
      include Raix::ChatCompletion
      attr_reader :workflow, :current_model

      def initialize(workflow)
        @workflow = workflow
        @current_model = nil
      end

      # Execute a chat completion with instrumentation
      def chat_completion(**kwargs)
        start_time = Time.now
        step_model = kwargs[:model]

        with_model(step_model) do
          ActiveSupport::Notifications.instrument("roast.chat_completion.start", {
            model: current_model || workflow.model,
            parameters: kwargs.except(:openai, :model),
          })

          # Call the parent module's chat_completion with model set
          # Skip model and openai from kwargs as they are handled here
          result = super(**kwargs.except(:model, :openai))
          execution_time = Time.now - start_time

          ActiveSupport::Notifications.instrument("roast.chat_completion.complete", {
            success: true,
            model: current_model || workflow.model,
            parameters: kwargs.except(:openai, :model),
            execution_time: execution_time,
            response_size: result.to_s.length,
          })
          result
        end
      rescue => e
        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.chat_completion.error", {
          error: e.class.name,
          message: e.message,
          model: step_model || workflow.model,
          parameters: kwargs.except(:openai, :model),
          execution_time: execution_time,
        })
        raise
      end

      # Temporarily switch the model for a block
      def with_model(model)
        previous_model = @current_model
        @current_model = model
        yield
      ensure
        @current_model = previous_model
      end

      # Override model accessor to use current_model or workflow's model
      def model
        @current_model || @workflow.model
      end

      # Delegate openai? to workflow for Raix compatibility
      def openai?
        @workflow.openai?
      end
    end
  end
end
