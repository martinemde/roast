# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class CodingAgentConfigTest < ActiveSupport::TestCase
      def setup
        @temp_dir = Dir.mktmpdir
        @workflow_path = File.join(@temp_dir, "test_workflow.yml")

        # Reset CodingAgent configuration
        Tools::CodingAgent.configured_command = nil
        Tools::CodingAgent.configured_options = {}
      end

      def teardown
        FileUtils.rm_rf(@temp_dir)
        Tools::CodingAgent.configured_command = nil
        Tools::CodingAgent.configured_options = {}
      end

      test "CodingAgent tool configuration with model option" do
        workflow_content = <<~YAML
          name: Test CodingAgent Config
          tools:
            - Roast::Tools::CodingAgent:
                model: opus
          steps:
            - test_step: "Test step"
        YAML

        File.write(@workflow_path, workflow_content)

        config = Configuration.new(@workflow_path)
        assert_equal ["Roast::Tools::CodingAgent"], config.tools
        assert_equal({ "model" => "opus" }, config.tool_config("Roast::Tools::CodingAgent"))

        # Initialize the workflow to trigger post_configuration_setup
        WorkflowInitializer.new(config).send(:post_configure_tools)

        assert_equal({ "model" => "opus" }, Tools::CodingAgent.configured_options)
      end

      test "CodingAgent tool configuration with multiple options" do
        workflow_content = <<~YAML
          name: Test CodingAgent Config
          tools:
            - Roast::Tools::CodingAgent:
                model: opus
                temperature: 0.7
                max_tokens: 1000
          steps:
            - test_step: "Test step"
        YAML

        File.write(@workflow_path, workflow_content)

        config = Configuration.new(@workflow_path)
        expected_config = {
          "model" => "opus",
          "temperature" => 0.7,
          "max_tokens" => 1000,
        }
        assert_equal expected_config, config.tool_config("Roast::Tools::CodingAgent")

        # Initialize the workflow to trigger post_configuration_setup
        WorkflowInitializer.new(config).send(:post_configure_tools)

        assert_equal expected_config, Tools::CodingAgent.configured_options
      end

      test "CodingAgent tool configuration with custom command and options" do
        workflow_content = <<~YAML
          name: Test CodingAgent Config
          tools:
            - Roast::Tools::CodingAgent:
                coding_agent_command: "custom-claude"
                model: opus
          steps:
            - test_step: "Test step"
        YAML

        File.write(@workflow_path, workflow_content)

        config = Configuration.new(@workflow_path)

        # Initialize the workflow to trigger post_configuration_setup
        WorkflowInitializer.new(config).send(:post_configure_tools)

        assert_equal "custom-claude", Tools::CodingAgent.configured_command
        assert_equal({ "model" => "opus" }, Tools::CodingAgent.configured_options)
      end
    end
  end
end
