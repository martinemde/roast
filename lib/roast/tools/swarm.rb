# frozen_string_literal: true

require "shellwords"

module Roast
  module Tools
    module Swarm
      extend self

      DEFAULT_CONFIG_PATHS = [
        ".swarm.yml",
        "swarm.yml",
        ".swarm/config.yml",
      ].freeze

      CONFIG_PATH_KEY = "path"
      private_constant :DEFAULT_CONFIG_PATHS, :CONFIG_PATH_KEY

      class << self
        def included(base)
          base.class_eval do
            function(
              :swarm,
              "Execute Claude Swarm to orchestrate multiple Claude Code instances. If the swarm is iterating on previous work, set continue to true.",
              prompt: {
                type: "string",
                description: "The prompt to send to the swarm agents",
                required: true,
              },
              path: {
                type: "string",
                description: "Path to the swarm configuration file (optional)",
                required: false,
              },
              include_context_summary: {
                type: "boolean",
                description: "Whether to include a summary of the current workflow context as system directive (default: false)",
                required: false,
              },
              continue: {
                type: "boolean",
                description: "Whether to continue where the previous swarm left off or start with a fresh context (default: false, start fresh)",
                required: false,
              },
            ) do |params|
              Roast::Tools::Swarm.call(
                params[:prompt],
                params[:path],
                include_context_summary: params[:include_context_summary].presence || false,
                continue: params[:continue].presence || false,
              )
            end
          end
        end

        def post_configuration_setup(base, config = {})
          @tool_config = config
        end

        attr_reader :tool_config
      end

      def call(prompt, step_path = nil, include_context_summary: false, continue: false)
        config_path = determine_config_path(step_path)

        if config_path.nil?
          return "Error: No swarm configuration file found. Please create a .swarm.yml file or specify a path."
        end

        unless File.exist?(config_path)
          return "Error: Swarm configuration file not found at: #{config_path}"
        end

        Roast::Helpers::Logger.info("🐝 Running Claude Swarm with config: #{config_path}\n")

        execute_swarm(prompt, config_path, include_context_summary:, continue:)
      rescue StandardError => e
        handle_error(e)
      end

      private

      def determine_config_path(step_path)
        # Priority: step-level path > tool-level path > default locations

        # 1. Check step-level path
        return step_path if step_path

        # 2. Check tool-level path from configuration
        if tool_config && tool_config[CONFIG_PATH_KEY]
          return tool_config[CONFIG_PATH_KEY]
        end

        # 3. Check default locations
        DEFAULT_CONFIG_PATHS.find { |path| File.exist?(path) }
      end

      def execute_swarm(prompt, config_path, include_context_summary:, continue:)
        # Prepare the final prompt with context summary if requested
        final_prompt = prepare_prompt(prompt, include_context_summary)

        # Build the swarm command with proper escaping
        command = build_swarm_command(final_prompt, config_path, continue:)

        result = ""

        # Execute the command directly with the prompt included
        IO.popen(command, err: [:child, :out]) do |io|
          result = io.read
        end

        exit_status = $CHILD_STATUS.exitstatus

        format_output(command, result, exit_status)
      end

      def build_swarm_command(prompt, config_path, continue:)
        # Build the claude-swarm command with properly escaped arguments
        command_parts = ["claude-swarm"]

        # Add --continue flag if specified
        command_parts << "--continue" if continue

        command_parts += [
          "--config",
          config_path,
          "--prompt",
          prompt,
        ]

        command_parts.shelljoin
      end

      def format_output(command, result, exit_status)
        "Command: #{command}\n" \
          "Exit status: #{exit_status}\n" \
          "Output:\n#{result}"
      end

      def handle_error(error)
        error_message = "Error running swarm: #{error.message}"
        Roast::Helpers::Logger.error("#{error_message}\n")
        Roast::Helpers::Logger.debug("#{error.backtrace.join("\n")}\n") if ENV["DEBUG"]
        error_message
      end

      def prepare_prompt(prompt, include_context_summary)
        return prompt unless include_context_summary

        context_summary = generate_context_summary(prompt)
        return prompt if context_summary.blank? || context_summary == "No relevant information found in the workflow context."

        # Prepend context summary as a system directive
        <<~PROMPT
          <system>
          #{context_summary}
          </system>

          #{prompt}
        PROMPT
      end

      def generate_context_summary(swarm_prompt)
        # Access the current workflow context if available
        workflow_context = Thread.current[:workflow_context]
        return unless workflow_context

        # Use ContextSummarizer to generate an intelligent summary
        summarizer = ContextSummarizer.new
        summarizer.generate_summary(workflow_context, swarm_prompt)
      rescue => e
        Roast::Helpers::Logger.debug("Failed to generate context summary: #{e.message}\n")
        nil
      end
    end
  end
end
