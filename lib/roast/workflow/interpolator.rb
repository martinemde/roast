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

        # Replace all {{expression}} with their evaluated values
        text.gsub(/\{\{([^}]+)\}\}/) do |match|
          expression = Regexp.last_match(1).strip
          begin
            # Evaluate the expression in the context
            @context.instance_eval(expression).to_s
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
