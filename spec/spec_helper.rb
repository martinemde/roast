# frozen_string_literal: true

# RSpec configuration for the Raix interface contract tests
#
# This file provides the basic setup needed to run the Raix interface contract
# tests without requiring the full Roast test environment.

require "bundler/setup"

# Load the gems we need for testing
require "rspec"

# Load Raix since that's what we're testing the interface for
begin
  require "raix"
  require "raix/chat_completion"
  require "raix/function_dispatch"
rescue LoadError
  puts "Warning: Raix gem not available. Install Raix to run these tests."
  puts "These tests are designed to run within the Raix project itself."
end

# Load Active Support for the `except` method used in some tests
begin
  require "active_support/core_ext/hash/except"
rescue LoadError
  # If Active Support isn't available, define a simple except method
  class Hash
    def except(*keys)
      dup.tap do |hash|
        keys.each { |key| hash.delete(key) }
      end
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Object`
  config.disable_monkey_patching!

  # Use the documentation formatter for detailed output
  config.default_formatter = "doc" if config.files_to_run.one?

  # Configure RSpec to expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up any thread-local state between tests
  config.after(:each) do
    Thread.current[:chat_completion_response] = nil
  end
end