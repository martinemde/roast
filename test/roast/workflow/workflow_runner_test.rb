# frozen_string_literal: true

require "test_helper"
require "roast/workflow/workflow_runner"
require "roast/workflow/configuration"
require "mocha/minitest"

class RoastWorkflowRunnerTest < ActiveSupport::TestCase
  def setup
    @configuration = mock("configuration")
    @configuration.stubs(:basename).returns("test_workflow")
    @configuration.stubs(:context_path).returns("/test/path")
    @configuration.stubs(:resource).returns(nil)
    @configuration.stubs(:name).returns("test_session")
    @configuration.stubs(:steps).returns(["step1", "step2"])
    @configuration.stubs(:config_hash).returns({})
    @configuration.stubs(:pre_processing).returns([])
    @configuration.stubs(:post_processing).returns([])

    @options = { output: "/tmp/output.txt", verbose: true }
    @runner = Roast::Workflow::WorkflowRunner.new(@configuration, @options)
  end

  def test_run_for_files_processes_each_file
    files = ["file1.rb", "file2.rb"]
    @configuration.stubs(:has_target?).returns(false)

    # Expect workflows to be created and executed for each file
    mock_workflow1 = create_mock_workflow
    mock_workflow2 = create_mock_workflow

    Roast::Workflow::BaseWorkflow.expects(:new).with(
      "file1.rb",
      has_entries(
        name: "test_workflow",
        context_path: "/test/path",
        resource: nil,
        session_name: "test_session",
        configuration: @configuration,
      ),
    ).returns(mock_workflow1)

    Roast::Workflow::BaseWorkflow.expects(:new).with(
      "file2.rb",
      has_entries(
        name: "test_workflow",
        context_path: "/test/path",
        resource: nil,
        session_name: "test_session",
        configuration: @configuration,
      ),
    ).returns(mock_workflow2)

    mock_executor = mock("executor")
    mock_executor.expects(:execute_steps).with(["step1", "step2"]).twice
    Roast::Workflow::WorkflowExecutor.expects(:new).twice.returns(mock_executor)

    assert_output(nil, /Running workflow for file: file1.rb.*Running workflow for file: file2.rb.*ROAST COMPLETE!/m) do
      @runner.run_for_files(files)
    end
  end

  def test_run_for_files_warns_when_target_present
    files = ["file1.rb"]
    @configuration.stubs(:has_target?).returns(true)
    @configuration.stubs(:target).returns("ignored_target.rb")

    mock_workflow = create_mock_workflow
    Roast::Workflow::BaseWorkflow.expects(:new).returns(mock_workflow)

    mock_executor = mock("executor")
    mock_executor.expects(:execute_steps)
    Roast::Workflow::WorkflowExecutor.expects(:new).returns(mock_executor)

    assert_output(nil, /WARNING: Ignoring target parameter.*ignored_target\.rb/) do
      @runner.run_for_files(files)
    end
  end

  def test_run_for_targets_processes_each_target_line
    @configuration.stubs(:target).returns("target1.rb\ntarget2.rb\n")

    mock_workflow1 = create_mock_workflow
    mock_workflow2 = create_mock_workflow

    Roast::Workflow::BaseWorkflow.expects(:new).with(
      "target1.rb",
      anything,
    ).returns(mock_workflow1)

    Roast::Workflow::BaseWorkflow.expects(:new).with(
      "target2.rb",
      anything,
    ).returns(mock_workflow2)

    mock_executor = mock("executor")
    mock_executor.expects(:execute_steps).twice
    Roast::Workflow::WorkflowExecutor.expects(:new).twice.returns(mock_executor)

    assert_output(nil, /Running workflow for file: target1.rb.*Running workflow for file: target2.rb/m) do
      @runner.run_for_targets
    end
  end

  def test_run_targetless_creates_workflow_with_nil_file
    mock_workflow = create_mock_workflow

    Roast::Workflow::BaseWorkflow.expects(:new).with(
      nil,
      has_entries(
        name: "test_workflow",
        context_path: "/test/path",
        resource: nil,
        session_name: "test_session",
        configuration: @configuration,
      ),
    ).returns(mock_workflow)

    mock_executor = mock("executor")
    mock_executor.expects(:execute_steps)
    Roast::Workflow::WorkflowExecutor.expects(:new).returns(mock_executor)

    assert_output(nil, /Running targetless workflow.*ROAST COMPLETE!/m) do
      @runner.run_targetless
    end
  end

  def test_handles_replay_option
    @options[:replay] = "step2"
    runner = Roast::Workflow::WorkflowRunner.new(@configuration, @options)

    mock_workflow = create_mock_workflow
    Roast::Workflow::BaseWorkflow.expects(:new).returns(mock_workflow)

    mock_replay_handler = mock("replay_handler")
    mock_replay_handler.expects(:process_replay).with(["step1", "step2"], "step2").returns(["step2"])
    Roast::Workflow::ReplayHandler.expects(:new).with(mock_workflow).returns(mock_replay_handler)

    mock_executor = mock("executor")
    mock_executor.expects(:execute_steps).with(["step2"])
    Roast::Workflow::WorkflowExecutor.expects(:new).returns(mock_executor)

    runner.run_targetless
  end

  private

  def create_mock_workflow
    mock("workflow").tap do |workflow|
      workflow.stubs(:output_file=)
      workflow.stubs(:verbose=)
      workflow.stubs(:concise=)
      workflow.stubs(:pause_step_name=)
      workflow.stubs(:output_file).returns("/tmp/output.txt")
      workflow.stubs(:final_output).returns("Final output")
      workflow.stubs(:session_name).returns("test_session")
      workflow.stubs(:file).returns("test_file.rb")
      workflow.stubs(:session_timestamp).returns(nil)
      workflow.stubs(:respond_to?).with(:session_name).returns(true)
      workflow.stubs(:respond_to?).with(:final_output).returns(true)
      workflow.stubs(:state).returns({})
      workflow.stubs(:transcript).returns([])

      # Mock output_manager for execution context
      mock_output_manager = mock("output_manager")
      mock_output_manager.stubs(:to_h).returns({ output: {}, final_output: [] })
      workflow.stubs(:output_manager).returns(mock_output_manager)
    end
  end
end
