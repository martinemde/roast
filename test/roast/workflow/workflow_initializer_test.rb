# frozen_string_literal: true

require "test_helper"
require "roast/workflow/workflow_initializer"
require "roast/workflow/configuration"
require "mocha/minitest"

class RoastWorkflowInitializerTest < ActiveSupport::TestCase
  def setup
    @workflow_path = fixture_file("workflow/workflow.yml")
    @configuration = Roast::Workflow::Configuration.new(@workflow_path)
    @initializer = Roast::Workflow::WorkflowInitializer.new(@configuration)

    # Stub out initializer loading to prevent side effects
    Roast::Initializers.stubs(:load_all)
  end

  def test_setup_loads_initializers_and_configures_tools
    Roast::Initializers.expects(:load_all)

    @initializer.setup
  end

  def test_includes_tools_when_configured
    @configuration.stubs(:tools).returns(["Roast::Tools::ReadFile", "Roast::Tools::Grep"])

    Roast::Workflow::BaseWorkflow.expects(:include).with(Raix::FunctionDispatch)
    Roast::Workflow::BaseWorkflow.expects(:include).with(Roast::Helpers::FunctionCachingInterceptor)
    Roast::Workflow::BaseWorkflow.expects(:include).with(Roast::Tools::ReadFile, Roast::Tools::Grep)

    @initializer.setup
  end

  def test_does_not_include_tools_when_none_configured
    @configuration.stubs(:tools).returns([])

    Roast::Workflow::BaseWorkflow.expects(:include).never

    @initializer.setup
  end

  def test_skips_api_client_configuration_when_api_token_present
    @configuration.stubs(:api_token).returns("test-token")
    @configuration.stubs(:api_provider).returns(:openai)

    # With the new implementation, if api_token is present,
    # it assumes it's already configured by an initializer
    OpenAI::Client.expects(:new).never

    @initializer.setup
  end

  def test_skips_openrouter_client_configuration_when_api_token_present
    # Skip this test if OpenRouter is not available
    if defined?(OpenRouter) && defined?(OpenRouter::Client)
      @configuration.stubs(:api_token).returns("test-token")
      @configuration.stubs(:api_provider).returns(:openrouter)

      # With the new implementation, if api_token is present,
      # it assumes it's already configured by an initializer
      OpenRouter::Client.expects(:new).never
      @initializer.setup
    else
      skip("OpenRouter gem not available")
    end
  end

  def test_handles_api_client_configuration_errors_gracefully
    @configuration.stubs(:api_token).returns(nil) # No token, so it will try to configure
    @configuration.stubs(:api_provider).returns(:openai)

    # It will raise an error about missing api_token
    Roast::Helpers::Logger.expects(:error).with("Error configuring API client: Missing api_token in workflow configuration")

    # Should re-raise the error
    assert_raises(RuntimeError) do
      @initializer.setup
    end
  end

  def test_raises_error_when_no_api_token
    @configuration.stubs(:api_token).returns(nil)
    @configuration.stubs(:api_provider).returns(:openai)

    OpenAI::Client.expects(:new).never

    # The new implementation raises an error when api_token is missing
    assert_raises(RuntimeError, "Missing api_token in workflow configuration") do
      @initializer.setup
    end
  end

  def test_raises_error_when_blank_api_token
    @configuration.stubs(:api_token).returns("")
    @configuration.stubs(:api_provider).returns(:openai)

    OpenAI::Client.expects(:new).never

    # The new implementation raises an error when api_token is blank
    assert_raises(RuntimeError, "Missing api_token in workflow configuration") do
      @initializer.setup
    end
  end

  def test_raises_error_for_unsupported_api_provider
    @configuration.stubs(:api_token).returns(nil)
    @configuration.stubs(:api_provider).returns(:unsupported)

    assert_raises(RuntimeError) do
      @initializer.setup
    end
  end
end
