# frozen_string_literal: true

module Roast
  module Workflow
    class Interpolator
      def initialize(context, logger: nil)
        @context = context
        @logger = logger || NullLogger.new
      end

      def interpolate(text)
        return text unless text.is_a?(String) && text.include?("{{") && text.include?("}}")

        # Check if this is a shell command context
        is_shell_command = text.strip.start_with?("$(") && text.strip.end_with?(")")

        # Replace all {{expression}} with their evaluated values
        text.gsub(/\{\{([^}]+)\}\}/) do |match|
          expression = Regexp.last_match(1).strip
          begin
            # Evaluate the expression in the context
            result = @context.instance_eval(expression).to_s

            # Escape backticks if this is a shell command to prevent command substitution
            if is_shell_command
              # Only escape backticks - they trigger command substitution even in double quotes
              result.gsub("`", "\\`")
            else
              result
            end
          rescue => e
            # Provide a detailed error message but preserve the original expression
            error_msg = "Error interpolating {{#{expression}}}: #{e.message}. This variable is not defined in the workflow context."
            @logger.error(error_msg)
            match # Preserve the original expression in the string
          end
        end
      end

      class NullLogger
        def error(_message); end
      end
    end
  end
end
