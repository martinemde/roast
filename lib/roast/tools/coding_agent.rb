# frozen_string_literal: true

require "roast/helpers/logger"
require "open3"
require "tempfile"
require "securerandom"

module Roast
  module Tools
    module CodingAgent
      extend self

      CONFIG_CODING_AGENT_COMMAND = "coding_agent_command"
      private_constant :CONFIG_CODING_AGENT_COMMAND

      @configured_command = nil

      class << self
        attr_accessor :configured_command

        def included(base)
          base.class_eval do
            function(
              :coding_agent,
              "AI-powered coding agent that runs Claude Code CLI with the given prompt",
              prompt: { type: "string", description: "The prompt to send to Claude Code" },
            ) do |params|
              Roast::Tools::CodingAgent.call(params[:prompt])
            end
          end
        end

        # Called after configuration is loaded
        def post_configuration_setup(base, config = {})
          self.configured_command = config[CONFIG_CODING_AGENT_COMMAND]
        end
      end

      def call(prompt)
        Roast::Helpers::Logger.info("🤖 Running CodingAgent\n")
        run_claude_code(prompt)
      rescue StandardError => e
        "Error running CodingAgent: #{e.message}".tap do |error_message|
          Roast::Helpers::Logger.error(error_message + "\n")
          Roast::Helpers::Logger.debug(e.backtrace.join("\n") + "\n") if ENV["DEBUG"]
        end
      end

      private

      def run_claude_code(prompt)
        Roast::Helpers::Logger.debug("🤖 Executing Claude Code CLI with prompt: #{prompt}\n")

        # Create a temporary file with a unique name
        timestamp = Time.now.to_i
        random_id = SecureRandom.hex(8)
        pid = Process.pid
        temp_file = Tempfile.new(["claude_prompt_#{timestamp}_#{pid}_#{random_id}", ".txt"])

        begin
          # Write the prompt to the file
          temp_file.write(prompt)
          temp_file.close

          # Run Claude Code CLI using the temp file as input
          stdout, stderr, status = Open3.capture3("cat #{temp_file.path} | #{claude_code_command}")

          if status.success?
            stdout
          else
            "Error running ClaudeCode: #{stderr}"
          end
        ensure
          # Always clean up the temp file
          temp_file.unlink
        end
      end

      def claude_code_command
        CodingAgent.configured_command || ENV["CLAUDE_CODE_COMMAND"] || "claude -p"
      end
    end
  end
end
