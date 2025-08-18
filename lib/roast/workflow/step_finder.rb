# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    # Finds step indices within workflow step arrays
    # Handles various step formats: strings, hashes, parallel arrays
    class StepFinder
      attr_reader :steps

      def initialize(steps = nil)
        @steps = steps || []
      end

      class << self
        def find_index(steps_array, step_name)
          new(steps_array).find_index(step_name)
        end
      end

      # Find the index of a step in the workflow steps array
      # @param step_name [String] The name of the step to find
      # @param steps_array [Array, nil] Optional steps array to search in
      # @return [Integer, nil] The index of the step, or nil if not found
      def find_index(step_name, steps_array = nil)
        search_array = steps_array || @steps
        # First, try direct search
        index = find_by_direct_search(search_array, step_name)
        return index if index

        # Fall back to extracted name search
        find_by_extracted_name(search_array, step_name)
      end

      # Extract the name from a step definition
      # @param step [String, Hash, Array] The step definition
      # @return [String, Array] The step name(s)
      def extract_name(step)
        case step
        when String
          step
        when Hash
          step.keys.first
        when Array
          # For arrays, extract names from all contained steps
          step.map { |s| extract_name(s) }
        end
      end

      private

      def find_by_direct_search(steps_array, step_name)
        steps_array.each_with_index do |step, index|
          case step
          when Hash
            # Could be {name: command} or {name: {substeps}}
            step_key = step.keys.first
            return index if step_key == step_name
          when Array
            # This is a parallel step container, search inside it
            if contains_step?(step, step_name)
              return index
            end
          when String
            return index if step == step_name
          end
        end
        nil
      end

      def find_by_extracted_name(steps_array, step_name)
        steps_array.each_with_index do |step, index|
          name = extract_name(step)
          if name.is_a?(Array)
            # For arrays (parallel steps), check if target is in the array
            return index if name.flatten.include?(step_name)
          elsif name == step_name
            return index
          end
        end
        nil
      end

      def contains_step?(parallel_steps, step_name)
        parallel_steps.any? do |substep|
          case substep
          when Hash
            substep.keys.first == step_name
          when String
            substep == step_name
          else
            false
          end
        end
      end
    end
  end
end
