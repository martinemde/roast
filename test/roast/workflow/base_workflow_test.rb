# frozen_string_literal: true

require "test_helper"
require "roast/workflow/base_workflow"
require "mocha/minitest"

class RoastWorkflowBaseWorkflowTest < ActiveSupport::TestCase
  FILE_PATH = File.join(Dir.pwd, "test/fixtures/files/test.rb")

  def setup
    # Use Mocha for stubbing/mocking
    Roast::Helpers::PromptLoader.stubs(:load_prompt).returns("Test prompt")
    Roast::Tools.stubs(:setup_interrupt_handler)
    Roast::Tools.stubs(:setup_exit_handler)
    ActiveSupport::Notifications.stubs(:instrument).returns(true)

    @mock_client = mock("client")

    # Configure Raix properly
    Raix.configure do |config|
      config.openrouter_client = @mock_client
      config.openai_client = @mock_client
      config.model = "gpt-4"
      config.max_tokens = 1024
      config.max_completion_tokens = 1024
      config.temperature = 0.7
    end
  end

  def teardown
    Roast::Helpers::PromptLoader.unstub(:load_prompt)
    Roast::Tools.unstub(:setup_interrupt_handler)
    Roast::Tools.unstub(:setup_exit_handler)
    ActiveSupport::Notifications.unstub(:instrument)

    # Reset Raix configuration to defaults
    Raix.configure do |config|
      config.openrouter_client = nil
      config.openai_client = nil
      config.model = Raix::Configuration::DEFAULT_MODEL
      config.max_tokens = Raix::Configuration::DEFAULT_MAX_TOKENS
      config.max_completion_tokens = Raix::Configuration::DEFAULT_MAX_COMPLETION_TOKENS
      config.temperature = Raix::Configuration::DEFAULT_TEMPERATURE
    end
  end

  test "initializes with file and sets up transcript" do
    Roast::Tools.expects(:setup_interrupt_handler)
    workflow = Roast::Workflow::BaseWorkflow.new(FILE_PATH)

    assert_equal FILE_PATH, workflow.file
    assert_equal [{ system: "Test prompt" }], workflow.transcript
  end

  test "initializes with nil file for targetless workflows" do
    Roast::Tools.expects(:setup_interrupt_handler)
    workflow = Roast::Workflow::BaseWorkflow.new(nil)

    assert_nil workflow.file
    assert_equal [{ system: "Test prompt" }], workflow.transcript
  end

  test "appends to final output and returns it" do
    workflow = Roast::Workflow::BaseWorkflow.new(FILE_PATH)
    workflow.append_to_final_output("Test output")
    assert_equal "Test output", workflow.final_output
  end

  test "handles ResourceNotFoundError correctly when Faraday::ResourceNotFound is raised" do
    workflow = Roast::Workflow::BaseWorkflow.new(FILE_PATH)

    mock_response = { body: { "error" => { "message" => "Model not found" } } }
    faraday_error = Faraday::ResourceNotFound.new(nil)
    faraday_error.stubs(:response).returns(mock_response)

    @mock_client.expects(:complete).raises(faraday_error)

    ActiveSupport::Notifications.expects(:instrument).with("roast.chat_completion.start", anything).once
    ActiveSupport::Notifications.expects(:instrument).with(
      "roast.chat_completion.error",
      has_entry(error: "Roast::ResourceNotFoundError"),
    ).once

    assert_raises(Roast::ResourceNotFoundError) do
      workflow.chat_completion
    end
  end

  test "handles other errors properly without conversion" do
    workflow = Roast::Workflow::BaseWorkflow.new(FILE_PATH)

    standard_error = StandardError.new("Some other error")

    @mock_client.expects(:complete).raises(standard_error)

    ActiveSupport::Notifications.expects(:instrument).with("roast.chat_completion.start", anything).once
    ActiveSupport::Notifications.expects(:instrument).with(
      "roast.chat_completion.error",
      has_entry(error: "StandardError"),
    ).once

    error = assert_raises(StandardError) do
      workflow.chat_completion
    end

    assert_equal "Some other error", error.message
  end
end
