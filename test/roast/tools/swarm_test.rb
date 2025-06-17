# frozen_string_literal: true

require "test_helper"

module Roast
  module Tools
    class SwarmTest < ActiveSupport::TestCase
      setup do
        # Reset tool config before each test
        Roast::Tools::Swarm.instance_variable_set(:@tool_config, nil)
      end

      test "call returns error when no config file is found" do
        # Mock that no default config files exist
        File.stub(:exist?, false) do
          result = Roast::Tools::Swarm.call("Test prompt")
          assert_match "Error: No swarm configuration file found", result
        end
      end

      test "call returns error when specified config file does not exist" do
        result = Roast::Tools::Swarm.call("Test prompt", "/nonexistent/path.yml")
        assert_match "Error: Swarm configuration file not found at:", result
        assert_match "/nonexistent/path.yml", result
      end

      test "post_configuration_setup stores tool config" do
        config = { "path" => "custom-swarm.yml", "other_option" => "value" }
        Roast::Tools::Swarm.post_configuration_setup(nil, config)

        assert_equal config, Roast::Tools::Swarm.tool_config
      end

      test "determine_config_path prioritizes step-level path" do
        # Set tool config
        Roast::Tools::Swarm.post_configuration_setup(nil, { "path" => "tool-config.yml" })

        # Private method test via send
        path = Roast::Tools::Swarm.send(:determine_config_path, "step-level.yml")
        assert_equal "step-level.yml", path
      end

      test "determine_config_path uses tool config when no step path" do
        # Set tool config
        Roast::Tools::Swarm.post_configuration_setup(nil, { "path" => "tool-config.yml" })

        # Private method test via send
        path = Roast::Tools::Swarm.send(:determine_config_path, nil)
        assert_equal "tool-config.yml", path
      end

      test "determine_config_path finds default config files" do
        # Mock that .swarm.yml exists
        File.stub(:exist?, ->(path) { path == ".swarm.yml" }) do
          path = Roast::Tools::Swarm.send(:determine_config_path, nil)
          assert_equal ".swarm.yml", path
        end
      end

      test "build_swarm_command escapes shell arguments properly" do
        command = Roast::Tools::Swarm.send(:build_swarm_command, 'Test with "quotes" and $vars', "config.yml", continue: false)

        # Check the command is properly escaped
        assert_match "claude-swarm", command
        assert_match "--config config.yml", command
        assert_match "--prompt", command
        # Shellwords escaping will handle special characters
        assert_match "Test", command
        assert_match "quotes", command
        refute_match "--continue", command
      end

      test "build_swarm_command includes continue flag when specified" do
        command = Roast::Tools::Swarm.send(:build_swarm_command, "Test prompt", "config.yml", continue: true)

        assert_match "claude-swarm --continue", command
        assert_match "--config config.yml", command
        assert_match "--prompt", command
      end

      test "format_output includes all necessary information" do
        output = Roast::Tools::Swarm.send(:format_output, "test command", "test output", 0)

        assert_match "Command: test command", output
        assert_match "Exit status: 0", output
        assert_match "Output:\ntest output", output
      end

      test "handle_error formats error messages properly" do
        error = StandardError.new("Test error")
        result = Roast::Tools::Swarm.send(:handle_error, error)
        assert_equal "Error running swarm: Test error", result
      end

      test "prepare_prompt returns original prompt when include_context_summary is false" do
        prompt = "Test prompt"
        result = Roast::Tools::Swarm.send(:prepare_prompt, prompt, false)
        assert_equal prompt, result
      end

      test "prepare_prompt includes context summary when available" do
        prompt = "Test prompt"
        mock_summary = "This is a context summary"

        Roast::Tools::Swarm.stub(:generate_context_summary, mock_summary) do
          result = Roast::Tools::Swarm.send(:prepare_prompt, prompt, true)

          assert_match "<system>", result
          assert_match mock_summary, result
          assert_match "</system>", result
          assert_match prompt, result
        end
      end

      test "prepare_prompt returns original when context summary is blank" do
        prompt = "Test prompt"

        Roast::Tools::Swarm.stub(:generate_context_summary, "") do
          result = Roast::Tools::Swarm.send(:prepare_prompt, prompt, true)
          assert_equal prompt, result
        end
      end

      test "prepare_prompt returns original when context summary says no relevant info" do
        prompt = "Test prompt"

        Roast::Tools::Swarm.stub(:generate_context_summary, "No relevant information found in the workflow context.") do
          result = Roast::Tools::Swarm.send(:prepare_prompt, prompt, true)
          assert_equal prompt, result
        end
      end

      test "included method registers swarm function with all parameters" do
        base_class = Class.new do
          class << self
            attr_accessor :registered_functions

            def function(name, description, **params)
              @registered_functions ||= {}
              @registered_functions[name] = { description: description, parameters: params }
            end
          end
        end

        Roast::Tools::Swarm.included(base_class)

        assert base_class.registered_functions.key?(:swarm)
        swarm_func = base_class.registered_functions[:swarm]
        assert_match "Execute Claude Swarm to orchestrate multiple Claude Code instances", swarm_func[:description]
        assert swarm_func[:parameters][:prompt][:required]
        refute swarm_func[:parameters][:path][:required]
        refute swarm_func[:parameters][:include_context_summary][:required]
        refute swarm_func[:parameters][:continue][:required]
        assert_equal "boolean", swarm_func[:parameters][:include_context_summary][:type]
        assert_equal "boolean", swarm_func[:parameters][:continue][:type]
      end
    end
  end
end
