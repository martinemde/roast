# frozen_string_literal: true

module Roast
  module Workflow
    # FIFO (First In, First Out) compaction strategy that removes oldest messages
    # while preserving recent messages and any messages related to retained steps
    class FifoCompactionStrategy < CompactionStrategy
      # Default percentage of messages to keep
      DEFAULT_KEEP_PERCENTAGE = 0.5

      def compact(transcript, workflow)
        return transcript if transcript.empty?

        # Calculate how many messages to keep
        keep_percentage = config[:keep_percentage] || DEFAULT_KEEP_PERCENTAGE
        messages_to_keep = (transcript.size * keep_percentage).ceil

        # Ensure we keep at least a minimum number of messages
        messages_to_keep = [messages_to_keep, 10].max

        # If we're already below the threshold, no need to compact
        return transcript if transcript.size <= messages_to_keep

        # Separate messages into those that must be retained and others
        retained_messages = []
        other_messages = []

        transcript.each_with_index do |message, index|
          if should_retain_message?(message, workflow, index)
            retained_messages << { message: message, index: index }
          else
            other_messages << { message: message, index: index }
          end
        end

        # Build the compacted transcript
        compacted_transcript = []

        # Add a system message explaining the compaction
        compacted_transcript << {
          role: "system",
          content: "Context has been compacted using FIFO strategy. Older messages have been removed to save space.",
        }

        # Keep all retained messages in their original positions
        retained_indices = retained_messages.map { |item| item[:index] }.to_set

        # Calculate how many other messages we can keep
        remaining_slots = messages_to_keep - retained_messages.size - 1 # -1 for system message

        if remaining_slots > 0
          # Take the most recent "other" messages
          recent_other_messages = other_messages.last(remaining_slots)

          # Merge retained and recent messages, maintaining order
          all_kept_indices = retained_indices + recent_other_messages.map { |item| item[:index] }.to_set

          # Add messages in their original order
          transcript.each_with_index do |message, index|
            if all_kept_indices.include?(index)
              compacted_transcript << message
            end
          end
        else
          # Only keep retained messages
          retained_messages.each do |item|
            compacted_transcript << item[:message]
          end
        end

        # Log the compaction
        Roast::Helpers::Logger.info("Context compacted (FIFO): #{transcript.size} messages → #{compacted_transcript.size} messages")

        compacted_transcript
      end

      private

      def should_retain_message?(message, workflow, index)
        # Always retain system messages
        return true if message[:role] == "system" || message["role"] == "system"

        # Check if this message relates to a retained step
        return true if retained_step?(message, workflow)

        # Check if this is one of the very recent messages (last 5)
        return true if index >= workflow.transcript.size - 5

        false
      end
    end
  end
end
