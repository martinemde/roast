# frozen_string_literal: true

require "test_helper"

module Roast
  module Helpers
    # NOTE: Lean towards speed over thoroughness here. Long running commands and timeouts over 0.5s are to be avoided.
    class CmdRunnerTest < ActiveSupport::TestCase
      test "capture2e and capture3 call track child processes" do
        CmdRunner.expects(:track_child_process).at_least(2)
        CmdRunner.capture2e("echo 'hello world'")
        CmdRunner.capture3("echo 'hello world'")
      end

      test "capture2e and capture3 call cleanup child processes" do
        CmdRunner.expects(:cleanup_child_process).at_least(2)
        CmdRunner.capture2e("echo 'hello world'")
        CmdRunner.capture3("echo 'hello world'")
      end

      test "capture3 timeout validation rejects invalid values" do
        assert_raises(ArgumentError) do
          CmdRunner.capture3("echo 'validation test'", timeout: -1)
        end

        assert_raises(ArgumentError) do
          CmdRunner.capture3("echo 'validation test'", timeout: 0)
        end

        assert_raises(ArgumentError) do
          CmdRunner.capture3("echo 'validation test'", timeout: CmdRunner::MAX_TIMEOUT + 1)
        end
      end

      test "capture3 completes before timeout for quick commands" do
        start_time = Time.now
        stdout, stderr, status = CmdRunner.capture3("echo 'quick'", timeout: 0.5)
        elapsed = Time.now - start_time
        output = stdout + stderr

        assert_equal "quick\n", output
        assert_equal 0, status.exitstatus
        assert_operator elapsed, :<, 0.5
      end

      test "capture3 runs simple commands successfully" do
        stdout, stderr, status = CmdRunner.capture3("echo 'hello world'")
        output = stdout + stderr

        assert_equal "hello world\n", output
        assert_equal 0, status.exitstatus
      end

      test "capture3 runs *args commands successfully" do
        stdout, stderr, status = CmdRunner.capture3("echo", "hello", "world")
        output = stdout + stderr

        assert_equal "hello world\n", output
        assert_equal 0, status.exitstatus
      end

      test "capture3 handles complex arguments safely with *args format" do
        complex_arg = "hello 'world' && echo 'dangerous'"
        stdout, stderr, status = CmdRunner.capture3("echo", complex_arg)
        output = stdout + stderr

        assert_includes output, "hello 'world' && echo 'dangerous'"
        assert_equal 0, status.exitstatus

        lines = output.strip.split("\n")
        assert_equal 1, lines.length, "Should only have one line of output, not execute shell commands"
      end

      test "capture3 supports environment variables" do
        stdout, stderr, status = CmdRunner.capture3({ "TEST_VAR" => "array_test" }, "ruby", "-e", "puts ENV['TEST_VAR']")
        output = stdout + stderr

        assert_equal "array_test\n", output
        assert_equal 0, status.exitstatus
      end

      test "capture3 captures both stdout and stderr" do
        stdout, stderr, status = CmdRunner.capture3("echo 'stdout'; echo 'stderr' >&2")
        output = stdout + stderr

        assert_includes output, "stdout"
        assert_includes output, "stderr"
        assert_equal 0, status.exitstatus
      end

      test "capture3 handles command failures" do
        stdout, stderr, status = CmdRunner.capture3("exit 42")
        output = stdout + stderr

        assert_equal "", output
        assert_equal 42, status.exitstatus
      end

      test "capture3 times out long-running commands" do
        start_time = Time.now

        error = assert_raises(Timeout::Error) do
          CmdRunner.capture3("sleep 5", timeout: 0.1)
        end

        elapsed = Time.now - start_time
        assert_operator elapsed, :<, 2.0
        assert_match(/timed out after 0.1 seconds/, error.message)
      end

      test "capture3 times out *args commands with proper error message" do
        start_time = Time.now

        error = assert_raises(Timeout::Error) do
          CmdRunner.capture3("sleep", "5", timeout: 0.1)
        end

        elapsed = Time.now - start_time
        assert_operator elapsed, :<, 2.0
        assert_match(/Command 'sleep 5'/, error.message)
        assert_match(/timed out after 0.1 seconds/, error.message)
      end

      test "capture3 prevents stdin hanging commands" do
        start_time = Time.now
        stdout, stderr, _ = CmdRunner.capture3("cat", timeout: 0.1)
        elapsed = Time.now - start_time
        output = stdout + stderr

        assert_operator elapsed, :<, 1.0
        assert_equal "", output
      end

      test "capture3 handles non-existent commands gracefully" do
        error = assert_raises(Errno::ENOENT) do
          CmdRunner.capture3("nonexistent_command_xyz_123", timeout: 1)
        end

        assert_match(/No such file or directory/, error.message)
      end

      test "timeout is reasonably accurate" do
        start_time = Time.now

        assert_raises(Timeout::Error) do
          CmdRunner.capture3("sleep 1", timeout: 0.5)
        end

        elapsed = Time.now - start_time
        assert_operator elapsed, :>=, 0.4
        assert_operator elapsed, :<=, 1.0
      end

      test "capture3 returns separate stdout and stderr" do
        stdout, stderr, status = CmdRunner.capture3("echo 'out'; echo 'err' >&2")

        assert_equal "out\n", stdout
        assert_equal "err\n", stderr
        assert_equal 0, status.exitstatus
      end

      test "capture3 runs without timeout when no timeout is passed" do
        Timeout.expects(:timeout).never
        CmdRunner.capture3("sleep 0.2")
      end

      test "normalize_timeout returns original value for valid timeouts" do
        assert_equal 15, CmdRunner.normalize_timeout(15)
        assert_equal 60, CmdRunner.normalize_timeout(60)
        assert_equal 1800, CmdRunner.normalize_timeout(1800)
      end

      test "normalize_timeout returns DEFAULT_TIMEOUT for non-positive values" do
        assert_equal CmdRunner::DEFAULT_TIMEOUT, CmdRunner.normalize_timeout(nil)
        assert_equal CmdRunner::DEFAULT_TIMEOUT, CmdRunner.normalize_timeout(0)
        assert_equal CmdRunner::DEFAULT_TIMEOUT, CmdRunner.normalize_timeout(-1)
        assert_equal CmdRunner::DEFAULT_TIMEOUT, CmdRunner.normalize_timeout(-100)
      end

      test "normalize_timeout caps at MAX_TIMEOUT for excessive values" do
        assert_equal CmdRunner::MAX_TIMEOUT, CmdRunner.normalize_timeout(5000)
        assert_equal CmdRunner::MAX_TIMEOUT, CmdRunner.normalize_timeout(10000)
        assert_equal CmdRunner::MAX_TIMEOUT, CmdRunner.normalize_timeout(CmdRunner::MAX_TIMEOUT + 1)
        assert_equal CmdRunner::MAX_TIMEOUT, CmdRunner.normalize_timeout(CmdRunner::MAX_TIMEOUT)
      end
    end
  end
end
