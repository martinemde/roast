# typed: false
# frozen_string_literal: true

module Roast
  module Tools
    class ContextSummarizer
      include Raix::ChatCompletion

      attr_reader :model

      def initialize(model: "o4-mini")
        @model = model
      end

      # Generate an intelligent summary of the workflow context
      # tailored to what the agent needs to know for its upcoming task
      #
      # @param workflow_context [Object] The workflow context from Thread.current
      # @param agent_prompt [String] The prompt the agent is about to execute
      # @return [String, nil] The generated summary or nil if generation fails
      def generate_summary(workflow_context, agent_prompt)
        return unless workflow_context&.workflow

        context_data = build_context_data(workflow_context.workflow)
        summary_prompt = build_summary_prompt(context_data, agent_prompt)

        # Use our own transcript for the summary generation
        self.transcript = []
        prompt(summary_prompt)

        result = chat_completion
        result&.strip
      rescue => e
        Roast::Helpers::Logger.debug("Failed to generate LLM context summary: #{e.message}\n")
        nil
      end

      private

      def build_context_data(workflow)
        data = {}

        # Add workflow description if available
        if workflow.config && workflow.config["description"]
          data[:workflow_description] = workflow.config["description"]
        end

        # Add step outputs if available
        if workflow.output && !workflow.output.empty?
          data[:step_outputs] = workflow.output.map do |step_name, output|
            # Include full output for context generation
            { step: step_name, output: output }
          end
        end

        # Add current working directory
        data[:working_directory] = Dir.pwd

        # Add workflow name if available
        if workflow.respond_to?(:name)
          data[:workflow_name] = workflow.name
        end

        data
      end

      def build_summary_prompt(context_data, agent_prompt)
        prompt_parts = []

        prompt_parts << "You are preparing a context summary for an AI coding agent (Claude Code) that is about to perform a task."
        prompt_parts << "\nThe agent's upcoming task is:"
        prompt_parts << "```"
        prompt_parts << agent_prompt
        prompt_parts << "```"

        prompt_parts << "\nBased on the following workflow context, provide a concise summary of ONLY the information that would be relevant for the agent to complete this specific task."

        if context_data[:workflow_description]
          prompt_parts << "\nWorkflow Description: #{context_data[:workflow_description]}"
        end

        if context_data[:workflow_name]
          prompt_parts << "\nWorkflow Name: #{context_data[:workflow_name]}"
        end

        if context_data[:working_directory]
          prompt_parts << "\nWorking Directory: #{context_data[:working_directory]}"
        end

        if context_data[:step_outputs] && !context_data[:step_outputs].empty?
          prompt_parts << "\nPrevious Step Outputs:"
          context_data[:step_outputs].each do |step_data|
            prompt_parts << "\n### Step: #{step_data[:step]}"
            prompt_parts << "Output: #{step_data[:output]}"
          end
        end

        prompt_parts << "\n\nGenerate a brief context summary that:"
        prompt_parts << "1. Focuses ONLY on information relevant to the agent's upcoming task"
        prompt_parts << "2. Highlights key findings, decisions, or outputs the agent should be aware of"
        prompt_parts << "3. Is concise and actionable (aim for 3-5 sentences)"
        prompt_parts << "4. Does not repeat information that would be obvious from the agent's prompt"
        prompt_parts << "\nIf there is no relevant context for this task, respond with 'No relevant information found in the workflow context.'"

        prompt_parts.join("\n")
      end
    end
  end
end
