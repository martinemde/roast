# frozen_string_literal: true

require "raix/chat_completion"
require "raix/function_dispatch"
require "active_support"
require "active_support/isolated_execution_state"
require "active_support/notifications"
require "active_support/core_ext/hash/indifferent_access"
require "roast/workflow/output_manager"
require "roast/workflow/chat_completion_manager"
require "roast/workflow/context_path_resolver"

module Roast
  module Workflow
    class BaseWorkflow
      include Raix::ChatCompletion

      attr_accessor :file,
        :concise,
        :output_file,
        :pause_step_name,
        :verbose,
        :name,
        :context_path,
        :resource,
        :session_name,
        :session_timestamp,
        :configuration,
        :model

      delegate :api_provider, :openai?, to: :configuration
      delegate :output, :output=, :append_to_final_output, :final_output, to: :output_manager

      def initialize(file = nil, name: nil, context_path: nil, resource: nil, session_name: nil, configuration: nil)
        @file = file
        @name = name || self.class.name.underscore.split("/").last
        @context_path = context_path || ContextPathResolver.resolve(self.class)
        @resource = resource || Roast::Resources.for(file)
        @session_name = session_name || @name
        @session_timestamp = nil
        @configuration = configuration

        # Initialize managers
        @output_manager = OutputManager.new
        @chat_completion_manager = ChatCompletionManager.new(self)

        # Setup prompt and handlers
        read_sidecar_prompt.then do |prompt|
          next unless prompt

          transcript << { system: prompt }
        end
        Roast::Tools.setup_interrupt_handler(transcript)
        Roast::Tools.setup_exit_handler(self)
      end

      # Delegate to chat completion manager with model handling
      def chat_completion(**kwargs)
        @chat_completion_manager.chat_completion(**kwargs)
      end

      # For backward compatibility and internal use
      def with_model(model, &block)
        @chat_completion_manager.with_model(model, &block)
      end

      def workflow
        self
      end

      # Expose output manager for state management
      attr_reader :output_manager

      private

      # Called by ChatCompletionManager to invoke the actual chat completion
      def super_chat_completion(**kwargs)
        super(**kwargs)
      end

      def read_sidecar_prompt
        Roast::Helpers::PromptLoader.load_prompt(self, file)
      end
    end
  end
end
