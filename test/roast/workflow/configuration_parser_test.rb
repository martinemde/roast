# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"
require "roast/workflow/configuration_parser"
require "active_support/notifications"

class RoastWorkflowConfigurationParserTest < ActiveSupport::TestCase
  def setup
    @original_openai_key = ENV.delete("OPENAI_API_KEY")
    @workflow_path = fixture_file("workflow/workflow.yml")
    @parser = Roast::Workflow::ConfigurationParser.new(@workflow_path)
  end

  def teardown
    ENV["OPENAI_API_KEY"] = @original_openai_key
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end

  def test_initialize_with_example_workflow
    assert_instance_of(Roast::Workflow::Configuration, @parser.configuration)
    assert_equal("run_coverage", @parser.configuration.steps.first)
  end

  def test_begin_without_files_or_target_runs_targetless_workflow
    executor = mock("WorkflowExecutor")
    executor.stubs(:execute_steps)
    Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

    workflow = mock("BaseWorkflow")
    workflow.stubs(:output).returns({})
    workflow.stubs(:final_output).returns("")
    workflow.stubs(:output_file).returns(nil)
    Roast::Workflow::BaseWorkflow.stubs(:new).returns(workflow)
    workflow.stubs(:output_file=)
    workflow.stubs(:verbose=)

    output = capture_stderr { @parser.begin! }
    assert_match(/Running targetless workflow/, output)
  end

  def test_begin_with_instrumentation_instruments_workflow_events
    test_file = fixture_file("test.rb")
    parser = Roast::Workflow::ConfigurationParser.new(@workflow_path, [test_file])
    events = []
    subscription = ActiveSupport::Notifications.subscribe(/roast\./) do |name, _start, _finish, _id, payload|
      events << { name: name, payload: payload }
    end

    executor = mock("WorkflowExecutor")
    executor.stubs(:execute_steps)
    Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

    begin
      parser.begin!
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    start_event = events.find { |e| e[:name] == "roast.workflow.start" }
    complete_event = events.find { |e| e[:name] == "roast.workflow.complete" }

    assert_not_nil(start_event)
    assert_equal(@workflow_path, start_event[:payload][:workflow_path])

    assert_not_nil(complete_event)
    assert_equal(true, complete_event[:payload][:success])
    assert_kind_of(Float, complete_event[:payload][:execution_time])
  end

  def test_begin_with_files_initializes_workflow_for_each_file
    test_file = fixture_file("test.rb")
    parser = Roast::Workflow::ConfigurationParser.new(@workflow_path, [test_file])
    executor = mock("WorkflowExecutor")
    # Use expects instead of stubs for verification
    Roast::Workflow::WorkflowExecutor.expects(:new).returns(executor)
    executor.stubs(:execute_steps)

    output = capture_stderr { parser.begin! }
    assert_match(/Running workflow for file: #{Regexp.escape(test_file)}/, output)
  end

  # StepFinder tests are now in step_finder_test.rb
  # These tests were moved to test the public API of StepFinder class

  # ReplayHandler tests are now in replay_handler_test.rb
  # These tests were moved to test the public API of ReplayHandler class

  def test_begin_with_replay_option_starts_execution_from_specified_step
    # Create a simple workflow file with steps
    Dir.mktmpdir do |tmpdir|
      workflow_file = File.join(tmpdir, "test_workflow.yml")
      File.write(workflow_file, <<~YAML)
        name: Test Workflow
        steps:
          - step1: $(echo "Step 1")
          - step2: $(echo "Step 2")
          - step3: $(echo "Step 3")
          - step4: $(echo "Step 4")
      YAML

      target_file = File.join(tmpdir, "target.txt")
      File.write(target_file, "test content")

      # Create parser with replay option
      parser = Roast::Workflow::ConfigurationParser.new(workflow_file, [target_file], { replay: "step3" })

      # Mock the executor to verify which steps are executed
      executor = mock("WorkflowExecutor")
      Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

      # Should only execute step3 and step4 when replaying from step3
      executor.expects(:execute_steps).with([{ "step3" => "$(echo \"Step 3\")" }, { "step4" => "$(echo \"Step 4\")" }]).at_least_once

      # Run the workflow
      capture_stderr { parser.begin! }
    end
  end

  def test_begin_with_replay_option_restores_state_when_available
    # Create a simple workflow file with steps
    Dir.mktmpdir do |tmpdir|
      workflow_file = File.join(tmpdir, "test_workflow.yml")
      File.write(workflow_file, <<~YAML)
        name: Test Workflow
        steps:
          - step1: $(echo "Step 1")
          - step2: $(echo "Step 2")
          - step3: $(echo "Step 3")
      YAML

      target_file = File.join(tmpdir, "target.txt")
      File.write(target_file, "test content")

      # Create parser with replay option
      parser = Roast::Workflow::ConfigurationParser.new(workflow_file, [target_file], { replay: "step2" })

      # Mock the state repository to simulate existing state
      state_repository = mock("FileStateRepository")
      Roast::Workflow::FileStateRepository.stubs(:new).returns(state_repository)
      state_repository.expects(:load_state_before_step).returns({
        step_name: "step1",
        output: { "step1" => "result1" },
      })

      # Mock the executor
      executor = mock("WorkflowExecutor")
      Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

      # Should execute only step2 and step3
      executor.expects(:execute_steps).with([{ "step2" => "$(echo \"Step 2\")" }, { "step3" => "$(echo \"Step 3\")" }]).at_least_once

      # Run the workflow
      capture_stderr { parser.begin! }
    end
  end

  def test_begin_with_replay_option_handles_timestamp
    # Create a simple workflow file with steps
    Dir.mktmpdir do |tmpdir|
      workflow_file = File.join(tmpdir, "test_workflow.yml")
      File.write(workflow_file, <<~YAML)
        name: Test Workflow
        steps:
          - step1: $(echo "Step 1")
          - step2: $(echo "Step 2")
          - step3: $(echo "Step 3")
          - step4: $(echo "Step 4")
      YAML

      target_file = File.join(tmpdir, "target.txt")
      File.write(target_file, "test content")

      timestamp = "20230101_000000_000"
      # Create parser with replay option including timestamp
      parser = Roast::Workflow::ConfigurationParser.new(workflow_file, [target_file], { replay: "#{timestamp}:step3" })

      # Mock the executor
      executor = mock("WorkflowExecutor")
      Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)
      executor.expects(:execute_steps).with([{ "step3" => "$(echo \"Step 3\")" }, { "step4" => "$(echo \"Step 4\")" }]).at_least_once

      # Expect the BaseWorkflow to receive session_timestamp
      timestamp_set = false
      Roast::Workflow::BaseWorkflow.any_instance.stubs(:session_timestamp=).with(timestamp) do
        timestamp_set = true
      end

      # Run the workflow
      capture_stderr { parser.begin! }

      # Verify the timestamp was set
      assert(timestamp_set, "Expected session_timestamp to be set to #{timestamp}")
    end
  end

  def test_begin_with_replay_option_runs_all_steps_when_step_not_found
    # Create a simple workflow file with steps
    Dir.mktmpdir do |tmpdir|
      workflow_file = File.join(tmpdir, "test_workflow.yml")
      File.write(workflow_file, <<~YAML)
        name: Test Workflow
        steps:
          - step1: $(echo "Step 1")
          - step2: $(echo "Step 2")
      YAML

      target_file = File.join(tmpdir, "target.txt")
      File.write(target_file, "test content")

      # Create parser with replay option for non-existent step
      parser = Roast::Workflow::ConfigurationParser.new(workflow_file, [target_file], { replay: "nonexistent_step" })

      # Mock the executor
      executor = mock("WorkflowExecutor")
      Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

      # Should execute all steps when step not found
      executor.expects(:execute_steps).with([{ "step1" => "$(echo \"Step 1\")" }, { "step2" => "$(echo \"Step 2\")" }]).at_least_once

      # Run the workflow and capture output
      output = capture_stderr { parser.begin! }
      assert_match(/Step nonexistent_step not found/, output)
    end
  end

  # restore_workflow_state tests are now in replay_handler_test.rb
  # These tests were moved to test the public API of ReplayHandler class
end
