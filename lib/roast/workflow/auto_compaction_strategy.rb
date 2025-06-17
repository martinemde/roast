# frozen_string_literal: true

module Roast
  module Workflow
    # Automatic compaction strategy that uses an LLM to analyze the transcript
    # and choose the best compaction approach
    class AutoCompactionStrategy < CompactionStrategy
      include Raix::ChatCompletion

      attr_reader :model

      def initialize(context_manager, config = {})
        super
        @model = config[:analysis_model] || "o4-mini"
      end

      def compact(transcript, workflow)
        # Use LLM to analyze and choose the best strategy
        strategy_name = analyze_and_choose_strategy(transcript, workflow)

        # Fallback to summarize if analysis fails
        strategy_name ||= "summarize"

        Roast::Helpers::Logger.info("Auto-compaction selected '#{strategy_name}' strategy based on LLM analysis")

        # Create and execute the chosen strategy
        strategy_class = case strategy_name
        when "fifo"
          FifoCompactionStrategy
        when "prune"
          PruneCompactionStrategy
        else
          SummarizeCompactionStrategy
        end

        strategy = strategy_class.new(context_manager, config)
        strategy.compact(transcript, workflow)
      end

      private

      def analyze_and_choose_strategy(transcript, workflow)
        # Build analysis prompt
        prompt = build_analysis_prompt(transcript, workflow)

        # Use our own transcript for the analysis
        self.transcript = []
        prompt(prompt)

        # Get LLM's recommendation
        result = chat_completion(json: true)

        # Extract strategy name from response
        result["strategy"] || result[:strategy]
      rescue => e
        Roast::Helpers::Logger.debug("Failed to analyze transcript for auto-compaction: #{e.message}")
        nil
      end

      def build_analysis_prompt(transcript, workflow)
        prompt_parts = []

        prompt_parts << "Analyze this workflow transcript and recommend the best compaction strategy."
        prompt_parts << "\nAvailable strategies:"
        prompt_parts << "1. 'summarize' - Create AI summaries of older messages (best for complex workflows)"
        prompt_parts << "2. 'fifo' - Keep most recent messages, discard oldest (best for long-running workflows)"
        prompt_parts << "3. 'prune' - Keep beginning and end, remove middle (best when setup context is important)"

        prompt_parts << "\nTranscript characteristics:"
        prompt_parts << "- Total messages: #{transcript.size}"
        prompt_parts << "- Has tool usage: #{workflow.tools&.any? || has_tool_calls?(transcript)}"
        prompt_parts << "- Message types: #{count_message_types(transcript)}"

        # Include sample of conversation structure
        prompt_parts << "\nFirst few messages:"
        transcript.first(5).each do |msg|
          role = msg[:role] || msg["role"]
          content = msg[:content] || msg["content"]
          prompt_parts << "#{role}: #{truncate(content, 100)}"
        end

        prompt_parts << "\nLast few messages:"
        transcript.last(5).each do |msg|
          role = msg[:role] || msg["role"]
          content = msg[:content] || msg["content"]
          prompt_parts << "#{role}: #{truncate(content, 100)}"
        end

        prompt_parts << "\nRespond with JSON containing your recommendation:"
        prompt_parts << '{"strategy": "summarize|fifo|prune", "reasoning": "Brief explanation"}'

        prompt_parts.join("\n")
      end

      def has_tool_calls?(transcript)
        transcript.any? do |message|
          content = message[:content] || message["content"]
          content.to_s.include?("function_call") || content.to_s.include?("tool_call")
        end
      end

      def count_message_types(transcript)
        types = transcript.group_by { |msg| msg[:role] || msg["role"] }
        types.transform_values(&:count).to_s
      end

      def truncate(text, max_length)
        return text if text.to_s.length <= max_length

        "#{text.to_s[0...max_length]}..."
      end
    end
  end
end
