# frozen_string_literal: true

module Roast
  module Workflow
    # Manages workflow metadata, providing a structure parallel to output
    # but specifically for internal metadata that shouldn't be user-facing
    class MetadataManager
      def initialize
        @metadata = ActiveSupport::HashWithIndifferentAccess.new
        @metadata_wrapper = nil
      end

      # Get metadata wrapped in DotAccessHash for dot notation access
      def metadata
        @metadata_wrapper ||= DotAccessHash.new(@metadata)
      end

      # Set metadata, ensuring it's always a HashWithIndifferentAccess
      def metadata=(value)
        @metadata = if value.is_a?(ActiveSupport::HashWithIndifferentAccess)
          value
        else
          ActiveSupport::HashWithIndifferentAccess.new(value)
        end
        # Reset the wrapper when metadata changes
        @metadata_wrapper = nil
      end

      # Get the raw metadata hash (for internal use)
      def raw_metadata
        @metadata
      end

      # Get a snapshot of the current state for persistence
      def to_h
        @metadata.to_h
      end

      # Restore state from a hash
      def from_h(data)
        return unless data

        self.metadata = data
      end

      # Store metadata for a specific step
      def store(step_name, key, value)
        @metadata[step_name] ||= {}
        @metadata[step_name][key] = value
        # Reset wrapper to reflect changes
        @metadata_wrapper = nil
      end

      # Retrieve metadata for a specific step and key
      def retrieve(step_name, key)
        @metadata.dig(step_name, key)
      end

      # Get all metadata for a specific step
      def for_step(step_name)
        @metadata[step_name]
      end

      # Check if metadata exists for a step
      def has_metadata?(step_name)
        @metadata.key?(step_name)
      end

      # Clear metadata for a specific step
      def clear_step(step_name)
        @metadata.delete(step_name)
        @metadata_wrapper = nil
      end

      # Clear all metadata
      def clear
        @metadata.clear
        @metadata_wrapper = nil
      end
    end
  end
end
