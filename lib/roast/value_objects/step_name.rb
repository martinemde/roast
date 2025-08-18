# typed: true
# frozen_string_literal: true

module Roast
  module ValueObjects
    # Value object representing a step name, which can be either a plain text prompt
    # or a reference to a step file
    class StepName
      attr_reader :value

      def initialize(name)
        @value = name.to_s.strip
        freeze
      end

      def plain_text?
        @value.include?(" ")
      end

      def file_reference?
        !plain_text?
      end

      def to_s
        @value
      end

      # Enables implicit conversion to String
      alias_method :to_str, :to_s

      def ==(other)
        case other
        when StepName
          value == other.value
        when String
          value == other
        else
          false
        end
      end

      def eql?(other)
        other.is_a?(StepName) && value == other.value
      end

      def hash
        [self.class, @value].hash
      end
    end
  end
end
