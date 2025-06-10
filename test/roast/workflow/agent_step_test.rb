# frozen_string_literal: true

require "test_helper"

class RoastWorkflowAgentStepTest < ActiveSupport::TestCase
  def setup
    # Mock the CodingAgent call
    Roast::Tools::CodingAgent.stubs(:call).returns("Agent response")

    # Mock chat completion for regular prompt
    @mock_openai_client = mock
    @mock_openai_client.stubs(:chat).returns({
      "choices" => [{ "message" => { "content" => "Regular LLM response" } }],
    })
    OpenAI::Client.stubs(:new).returns(@mock_openai_client)

    # Store original env
    @original_openai_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-key"
  end

  def teardown
    Roast::Tools::CodingAgent.unstub(:call)
    OpenAI::Client.unstub(:new)
    ENV["OPENAI_API_KEY"] = @original_openai_key
  end

  test "agent step type is recognized correctly" do
    assert Roast::Workflow::StepTypeResolver.agent_step?("^my_prompt")
    refute Roast::Workflow::StepTypeResolver.agent_step?("my_prompt")
    refute Roast::Workflow::StepTypeResolver.agent_step?("$(command)")
  end

  test "extract_name strips ^ prefix for agent steps" do
    assert_equal "my_prompt", Roast::Workflow::StepTypeResolver.extract_name("^my_prompt")
    assert_equal "regular_prompt", Roast::Workflow::StepTypeResolver.extract_name("regular_prompt")
  end

  test "resolve returns AGENT_STEP for ^ prefixed steps" do
    step_type = Roast::Workflow::StepTypeResolver.resolve("^my_prompt")
    assert_equal Roast::Workflow::StepTypeResolver::AGENT_STEP, step_type
  end

  test "agent step loads AgentStep class when agent flag is true" do
    # Create a mock workflow
    workflow = mock
    workflow.stubs(:resource).returns(nil)
    workflow.stubs(:output).returns({})
    workflow.stubs(:transcript).returns([])

    # Create a temporary directory structure for the test
    Dir.mktmpdir do |tmpdir|
      # Create prompt directories
      agent_prompt_dir = File.join(tmpdir, "agent_prompt")
      regular_prompt_dir = File.join(tmpdir, "regular_prompt")
      Dir.mkdir(agent_prompt_dir)
      Dir.mkdir(regular_prompt_dir)

      # Create prompt files
      File.write(File.join(agent_prompt_dir, "prompt.md"), "Agent prompt content")
      File.write(File.join(regular_prompt_dir, "prompt.md"), "Regular prompt content")

      # Create step loader
      step_loader = Roast::Workflow::StepLoader.new(workflow, {}, tmpdir)

      # Load regular prompt step (with directory, it loads BaseStep)
      regular_step = step_loader.load("regular_prompt", agent: false)
      assert_instance_of Roast::Workflow::BaseStep, regular_step

      # Load agent step (with directory and agent flag, it loads AgentStep)
      agent_step = step_loader.load("agent_prompt", agent: true)
      assert_instance_of Roast::Workflow::AgentStep, agent_step
    end
  end

  test "agent step calls CodingAgent directly without LLM translation" do
    # Create a mock workflow
    workflow = mock
    workflow.stubs(:resource).returns(nil)
    workflow.stubs(:output).returns({})
    workflow.stubs(:transcript).returns([])
    workflow.stubs(:append_to_final_output)
    workflow.stubs(:file).returns(nil)

    # Create agent step
    agent_step = Roast::Workflow::AgentStep.new(workflow, name: "test_agent")

    # Mock the prompt loader to return our test prompt
    Roast::Helpers::PromptLoader.stubs(:load_prompt).returns("Test agent prompt")

    # Execute the step
    result = agent_step.call

    # Verify the result
    assert_equal "Agent response", result

    # Verify CodingAgent was called - we stubbed it in setup
    # Since we're using mocha stubs, we can't use received method
    # The test passes if the call doesn't raise an error
  end

  test "step executor coordinator handles agent steps" do
    # Create mock dependencies
    workflow = mock
    workflow.stubs(:output).returns({})
    config_mock = mock
    config_mock.stubs(:workflow_path).returns("/test/workflow.yml")
    workflow.stubs(:config).returns(config_mock)

    state_manager = mock
    state_manager.stubs(:save_state)

    error_handler = mock
    error_handler.stubs(:with_error_handling).yields

    step_orchestrator = mock
    step_orchestrator.expects(:execute_step).with("my_prompt", exit_on_error: true, step_key: nil, agent: true).returns("agent result")

    context = Roast::Workflow::WorkflowContext.new(
      workflow:,
      config_hash: {},
      context_path: "/test",
    )

    dependencies = {
      workflow_executor: mock,
      state_manager:,
      error_handler:,
      step_orchestrator:,
    }

    coordinator = Roast::Workflow::StepExecutorCoordinator.new(context:, dependencies:)

    # Execute an agent step
    result = coordinator.execute("^my_prompt")
    assert_equal "agent result", result
  end
end
