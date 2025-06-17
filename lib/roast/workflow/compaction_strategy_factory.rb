# frozen_string_literal: true

module Roast
  module Workflow
    # Factory for creating compaction strategies
    class CompactionStrategyFactory
      STRATEGIES = {
        "auto" => AutoCompactionStrategy,
        "summarize" => SummarizeCompactionStrategy,
        "fifo" => FifoCompactionStrategy,
        "prune" => PruneCompactionStrategy,
      }.freeze

      def self.create(strategy_name, context_manager, config = {})
        strategy_class = STRATEGIES[strategy_name]

        unless strategy_class
          raise ArgumentError, "Unknown compaction strategy: #{strategy_name}. Available strategies: #{STRATEGIES.keys.join(", ")}"
        end

        strategy_class.new(context_manager, config)
      end
    end
  end
end
