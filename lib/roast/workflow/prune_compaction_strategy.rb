# frozen_string_literal: true

module Roast
  module Workflow
    # Prune compaction strategy that keeps the beginning and end of the conversation
    # while removing messages from the middle
    class PruneCompactionStrategy < CompactionStrategy
      # Default number of messages to keep from beginning and end
      DEFAULT_KEEP_START = 5
      DEFAULT_KEEP_END = 20

      def compact(transcript, workflow)
        return transcript if transcript.empty?

        keep_start = config[:keep_start] || DEFAULT_KEEP_START
        keep_end = config[:keep_end] || DEFAULT_KEEP_END
        total_to_keep = keep_start + keep_end

        # If transcript is small enough, don't compact
        return transcript if transcript.size <= total_to_keep

        # Build compacted transcript
        compacted_transcript = []

        # Keep the beginning messages (for initial context)
        compacted_transcript.concat(transcript.first(keep_start))

        # Add a system message explaining what was removed
        removed_count = transcript.size - total_to_keep
        compacted_transcript << {
          role: "system",
          content: "Context pruned: #{removed_count} messages from the middle of the conversation have been removed to save space.",
        }

        # Keep the end messages (for recent context)
        compacted_transcript.concat(transcript.last(keep_end))

        # Log the compaction
        Roast::Helpers::Logger.info("Context compacted (prune): #{transcript.size} messages → #{compacted_transcript.size} messages")

        compacted_transcript
      end
    end
  end
end
