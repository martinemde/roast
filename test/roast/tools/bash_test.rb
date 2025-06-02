# frozen_string_literal: true

require "test_helper"

module Roast
  module Tools
    class BashTest < ActiveSupport::TestCase
      test "executes bash commands without restrictions" do
        result = Roast::Tools::Bash.call("echo 'Hello from Bash!'")
        assert_match(/Command: echo 'Hello from Bash!'/, result)
        assert_match(/Exit status: 0/, result)
        assert_match(/Hello from Bash!/, result)
      end

      test "executes commands that would be restricted in Cmd tool" do
        # Commands like rm, curl, wget that aren't in Cmd's default allowed list
        result = Roast::Tools::Bash.call("echo 'Simulating restricted command'")
        assert_match(/Command: echo 'Simulating restricted command'/, result)
        assert_match(/Exit status: 0/, result)
        assert_match(/Simulating restricted command/, result)
      end

      test "handles command execution with non-zero exit status" do
        result = Roast::Tools::Bash.call("false")
        assert_match(/Command: false/, result)
        assert_match(/Exit status: 1/, result)
      end

      test "handles commands with arguments and pipes" do
        result = Roast::Tools::Bash.call("echo 'test' | grep 'test'")
        assert_match(/Command: echo 'test' | grep 'test'/, result)
        assert_match(/Exit status: 0/, result)
        assert_match(/test/, result)
      end

      test "handles command execution errors gracefully" do
        result = Roast::Tools::Bash.call("nonexistent_command_xyz_123")
        assert_match(/Error executing bash command:/, result)
      end

      test "formats output correctly" do
        result = Roast::Tools::Bash.call("echo 'Line 1'; echo 'Line 2'")

        lines = result.split("\n")
        assert_match(/^Command: echo 'Line 1'; echo 'Line 2'$/, lines[0])
        assert_match(/^Exit status: 0$/, lines[1])
        assert_equal "Output:", lines[2]
        assert_match(/Line 1/, lines[3])
        assert_match(/Line 2/, lines[4])
      end

      test "executes in current working directory" do
        result = Roast::Tools::Bash.call("pwd")
        assert_match(/Command: pwd/, result)
        assert_match(/Exit status: 0/, result)
        assert_match(Dir.pwd, result)
      end

      test "handles complex bash constructs" do
        result = Roast::Tools::Bash.call("for i in 1 2 3; do echo $i; done")
        assert_match(/Command: for i in 1 2 3; do echo \$i; done/, result)
        assert_match(/Exit status: 0/, result)
        assert_match(/1/, result)
        assert_match(/2/, result)
        assert_match(/3/, result)
      end

      test "logs warning message by default" do
        original_logger = Roast::Helpers::Logger
        mock_logger = Minitest::Mock.new

        # Set up expectations for the mock
        mock_logger.expect(:info, nil, [String])
        mock_logger.expect(:warn, nil, ["⚠️  WARNING: Unrestricted bash execution - use with caution!\n"])

        # Replace the logger temporarily
        Roast::Helpers.const_set(:Logger, mock_logger)

        Roast::Tools::Bash.call("echo 'test'")

        mock_logger.verify
      ensure
        # Restore the original logger
        Roast::Helpers.const_set(:Logger, original_logger)
      end

      test "suppresses warning when ROAST_BASH_WARNINGS is false" do
        original_logger = Roast::Helpers::Logger
        mock_logger = Minitest::Mock.new

        # Set up expectations - no warn call expected
        mock_logger.expect(:info, nil, [String])

        # Set environment variable
        ENV["ROAST_BASH_WARNINGS"] = "false"

        # Replace the logger temporarily
        Roast::Helpers.const_set(:Logger, mock_logger)

        Roast::Tools::Bash.call("echo 'test'")

        mock_logger.verify
      ensure
        # Restore the original logger and environment
        Roast::Helpers.const_set(:Logger, original_logger)
        ENV.delete("ROAST_BASH_WARNINGS")
      end

      class DummyWorkflow
        class << self
          attr_accessor :registered_functions

          def function(name, description, **params, &block)
            @registered_functions ||= {}
            @registered_functions[name] = {
              description: description,
              params: params,
              block: block,
            }
          end
        end
      end

      test "included method registers bash function" do
        DummyWorkflow.registered_functions = {}

        Roast::Tools::Bash.included(DummyWorkflow)

        # Check that bash function was registered
        assert DummyWorkflow.registered_functions.key?(:bash)

        bash_func = DummyWorkflow.registered_functions[:bash]
        assert_match(/Execute any bash command without restrictions/, bash_func[:description])
        assert_match(/WARNING/, bash_func[:description])

        # Check params
        assert_equal "string", bash_func[:params][:command][:type]
        assert_equal true, bash_func[:params][:command][:required]

        # Test the function block
        result = bash_func[:block].call({ command: "echo 'test from function'" })
        assert_match(/test from function/, result)
      end
    end
  end
end
