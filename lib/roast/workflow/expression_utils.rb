# typed: false
# frozen_string_literal: true

module Roast
  module Workflow
    # Shared utilities for detecting and extracting expressions
    module ExpressionUtils
      # Check if the input is a Ruby expression in {{...}}
      def ruby_expression?(input)
        return false unless input.is_a?(String)

        input.strip.start_with?("{{") && input.strip.end_with?("}}")
      end

      # Check if the input is a Bash command in $(...)
      def bash_command?(input)
        return false unless input.is_a?(String)

        input.strip.start_with?("$(") && input.strip.end_with?(")")
      end

      # Extract the expression from {{...}}
      def extract_expression(input)
        return input unless ruby_expression?(input)

        input.strip[2...-2].strip
      end

      # Extract the command from $(...)
      def extract_command(input)
        return input unless bash_command?(input)

        input.strip[2...-1].strip
      end
    end
  end
end
