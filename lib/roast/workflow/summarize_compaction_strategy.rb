# frozen_string_literal: true

module Roast
  module Workflow
    # Compaction strategy that summarizes older messages to reduce token usage
    class SummarizeCompactionStrategy < CompactionStrategy
      def compact(transcript, workflow)
        return transcript if transcript.empty?

        # Find the point to start summarizing (keep recent messages intact)
        cutoff_index = calculate_cutoff_index(transcript)
        return transcript if cutoff_index <= 0

        # Split transcript into parts
        messages_to_summarize = transcript[0...cutoff_index]
        recent_messages = transcript[cutoff_index..]

        # Generate summary of older messages
        summary = generate_summary(messages_to_summarize, workflow)

        # Build compacted transcript
        compacted_transcript = []

        # Add system message explaining the summary
        compacted_transcript << {
          role: "system",
          content: "Previous conversation has been summarized to save context space. Summary follows:",
        }

        # Add the summary
        compacted_transcript << {
          role: "assistant",
          content: summary,
        }

        # Add recent messages
        compacted_transcript.concat(recent_messages)

        # Log the compaction
        Roast::Helpers::Logger.info("Context compacted: #{transcript.size} messages → #{compacted_transcript.size} messages")

        compacted_transcript
      end

      private

      def calculate_cutoff_index(transcript)
        # Keep at least the last 20% of messages intact
        min_recent_messages = (transcript.size * 0.2).ceil

        # But always keep at least 5 recent messages
        min_recent_messages = [min_recent_messages, 5].max

        # Don't summarize if we have too few messages
        return 0 if transcript.size <= min_recent_messages * 2

        transcript.size - min_recent_messages
      end

      def generate_summary(messages, workflow)
        # Create a specialized summarizer for transcript compaction
        summarizer = TranscriptSummarizer.new(
          retain_steps: retain_steps,
          workflow: workflow,
        )

        summary = summarizer.summarize_messages(messages)

        # Fallback if summarization fails
        summary || "Previous conversation contained #{messages.size} messages discussing workflow execution."
      end
    end

    # Specialized summarizer for conversation transcripts
    class TranscriptSummarizer
      include Raix::ChatCompletion

      attr_reader :retain_steps, :workflow, :model

      def initialize(retain_steps:, workflow:, model: "o4-mini")
        @retain_steps = retain_steps
        @workflow = workflow
        @model = model
      end

      def summarize_messages(messages)
        return if messages.empty?

        # Build the summarization prompt
        prompt = build_summarization_prompt(messages)

        # Use our own transcript for the summary generation
        self.transcript = []
        prompt(prompt)

        result = chat_completion
        result&.strip
      rescue => e
        Roast::Helpers::Logger.debug("Failed to generate transcript summary: #{e.message}")
        nil
      end

      private

      def build_summarization_prompt(messages)
        prompt_parts = []

        prompt_parts << "Summarize the following conversation transcript from a workflow execution."
        prompt_parts << "Focus on:"
        prompt_parts << "1. Key decisions and outcomes"
        prompt_parts << "2. Important data or results discovered"
        prompt_parts << "3. Any errors or issues encountered"
        prompt_parts << "4. The overall progress and state of the workflow"

        if retain_steps.any?
          prompt_parts << "\nPay special attention to these critical steps: #{retain_steps.join(", ")}"
        end

        prompt_parts << "\nTranscript to summarize:"
        prompt_parts << "---"

        messages.each do |msg|
          role = msg[:role] || msg["role"]
          content = msg[:content] || msg["content"]
          prompt_parts << "#{role.upcase}: #{content}"
        end

        prompt_parts << "---"
        prompt_parts << "\nProvide a concise summary that preserves the essential information and context."
        prompt_parts << "The summary should be detailed enough that someone could understand what happened without seeing the original messages."

        prompt_parts.join("\n")
      end
    end
  end
end
