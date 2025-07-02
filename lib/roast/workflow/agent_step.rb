# frozen_string_literal: true

module Roast
  module Workflow
    class AgentStep < BaseStep
      attr_accessor :include_context_summary, :continue

      def initialize(workflow, **kwargs)
        super
        # Set default values for agent-specific options
        @include_context_summary = false
        @continue = false
      end

      def call
        # For inline prompts (detected by plain text step names), use the name as the prompt
        # For file-based steps, load from the prompt file
        prompt_content = if name.plain_text?
          name.to_s
        else
          read_sidecar_prompt
        end

        # Use agent-specific configuration that was applied by StepLoader
        agent_options = {
          include_context_summary: @include_context_summary,
          continue: @continue,
        }

        # Call CodingAgent directly with the prompt content and options
        result = Roast::Tools::CodingAgent.call(prompt_content, **agent_options)

        # Parse as JSON if json: true is configured (since CodingAgent response is not handled by Raix)
        if @json && result.is_a?(String)
          # Don't try to parse error messages as JSON
          if result.start_with?("Error running CodingAgent:")
            raise result
          end

          # Strip Markdown code block indicators surrounding JSON data in response if present
          lines = result.strip.split("\n")

          # Check if first line is ```json or ``` (with optional trailing whitespace)
          # and last line is ``` (with optional trailing whitespace)
          cleaned_result = if lines.length >= 2 &&
              (lines.first.strip == "```json" || lines.first.strip == "```") &&
              lines.last.strip == "```"
            # Remove first and last lines
            lines[1..-2].join("\n")
          else
            result
          end

          begin
            result = JSON.parse(cleaned_result)
          rescue JSON::ParserError => e
            raise "Failed to parse CodingAgent result as JSON: #{e.message}"
          end
        end

        # Process output if print_response is enabled
        process_output(result, print_response:)

        # Apply coercion if configured
        apply_coercion(result)
      end
    end
  end
end
