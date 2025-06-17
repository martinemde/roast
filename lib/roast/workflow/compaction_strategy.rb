# frozen_string_literal: true

module Roast
  module Workflow
    # Base class for context compaction strategies
    class CompactionStrategy
      attr_reader :context_manager, :config

      def initialize(context_manager, config = {})
        @context_manager = context_manager
        @config = config
      end

      # Compact the conversation transcript to reduce token usage
      # @param transcript [Array<Hash>] The current conversation transcript
      # @param workflow [Object] The workflow instance
      # @return [Array<Hash>] The compacted transcript
      def compact(transcript, workflow)
        raise NotImplementedError, "Subclasses must implement #compact"
      end

      protected

      # Get the list of step names to retain in full
      def retain_steps
        config[:retain_steps] || []
      end

      # Check if a message relates to a retained step
      def retained_step?(message, workflow)
        return false unless message[:role] == "assistant"

        retain_steps.any? do |step_name|
          workflow.output[step_name] &&
            message[:content]&.include?(workflow.output[step_name].to_s)
        end
      end
    end
  end
end
