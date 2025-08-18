# typed: false
# frozen_string_literal: true

module Roast
  module Workflow
    # Factory for creating the appropriate StateRepository implementation
    class StateRepositoryFactory
      class << self
        def create(type = nil)
          type ||= default_type

          case type.to_s
          when "sqlite"
            # Lazy load the SQLite repository only when needed
            Roast::Workflow::SqliteStateRepository.new
          when "file", "filesystem"
            Roast::Workflow::FileStateRepository.new
          else
            raise ArgumentError, "Unknown state repository type: #{type}. Valid types are: sqlite, file"
          end
        end

        private

        def default_type
          # Check environment variable first (for backwards compatibility)
          if ENV["ROAST_STATE_STORAGE"]
            ENV["ROAST_STATE_STORAGE"].downcase
          else
            # Default to SQLite for better functionality
            "sqlite"
          end
        end
      end
    end
  end
end
