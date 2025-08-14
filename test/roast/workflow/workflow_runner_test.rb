# frozen_string_literal: true

require "test_helper"

class RoastWorkflowRunnerTest < ActiveSupport::TestCase
  def setup
    # Create a simple test workflow
    @tmpdir = Dir.mktmpdir
    @workflow_path = File.join(@tmpdir, "test_workflow.yml")
    File.write(@workflow_path, <<~YAML)
      name: test_workflow
      tools: []
      steps:
        - step1: $(echo "Step 1")
        - step2: $(echo "Step 2")
    YAML
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_run_for_files_processes_each_file
    # Create test files
    file1 = File.join(@tmpdir, "file1.rb")
    file2 = File.join(@tmpdir, "file2.rb")
    File.write(file1, "# File 1")
    File.write(file2, "# File 2")
    files = [file1, file2]

    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path)
    # Run and verify output
    assert_output(nil, /Running workflow for file: #{Regexp.escape(file1)}.*Running workflow for file: #{Regexp.escape(file2)}.*ROAST COMPLETE!/m) do
      runner.run_for_files(files)
    end
  end

  def test_run_for_files_warns_when_target_present
    # Create a workflow with a target
    File.write(@workflow_path, <<~YAML)
      name: test_workflow
      target: "ignored_target.rb"
      tools: []
      steps:
        - step1: $(echo "Step 1")
    YAML

    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path, { output: "/tmp/output.txt", verbose: true })

    file1 = File.join(@tmpdir, "file1.rb")
    File.write(file1, "# File 1")
    files = [file1]

    assert_output(nil, /WARNING: Ignoring target parameter.*ignored_target\.rb/) do
      runner.run_for_files(files)
    end
  end

  def test_run_for_targets_processes_each_target_line
    # Create target files
    target1 = File.join(@tmpdir, "target1.rb")
    target2 = File.join(@tmpdir, "target2.rb")
    File.write(target1, "# Target 1")
    File.write(target2, "# Target 2")

    # Create workflow with targets
    File.write(@workflow_path, <<~YAML)
      name: test_workflow
      target: "#{target1}\n#{target2}"
      tools: []
      steps:
        - step1: $(echo "Step 1")
    YAML

    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path, @options)

    output = capture_io { runner.run_for_targets }
    # The target appears as a single line with both files
    assert_match(/Running workflow for file:/, output.join)
    assert_match(/ROAST COMPLETE!/, output.join)
  end

  def test_run_targetless_creates_workflow_with_nil_file
    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path)
    assert_output(nil, /Running targetless workflow.*ROAST COMPLETE!/m) do
      runner.run_targetless
    end
  end

  def test_initialize_with_example_workflow
    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path)
    assert_instance_of(Roast::Workflow::Configuration, runner.configuration)
    assert_equal({ "step1" => "$(echo \"Step 1\")" }, runner.configuration.steps.first)
  end

  def test_begin_without_files_or_target_runs_targetless_workflow
    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path)
    _, err = capture_io { runner.begin! }
    assert_match(/Running targetless workflow/, err)
  end

  def test_begin_with_instrumentation_instruments_workflow_events
    test_file = fixture_file("test.rb")
    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path, [test_file])
    events = []
    subscription = ActiveSupport::Notifications.subscribe(/roast\./) do |name, _start, _finish, _id, payload|
      events << { name: name, payload: payload }
    end

    begin
      capture_io { runner.begin! }
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
    runner = Roast::Workflow::WorkflowRunner.new(@workflow_path, [test_file])

    _, err = capture_io { runner.begin! }
    assert_match(/Running workflow for file: #{Regexp.escape(test_file)}/, err)
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
      runner = Roast::Workflow::WorkflowRunner.new(workflow_file, [target_file], { replay: "step3" })

      # Run the workflow and check output behavior
      _, err = capture_io { runner.begin! }
      # When replaying from step3, we should see that it's replaying
      assert_match(/Replaying from step: step3/, err)
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
      runner = Roast::Workflow::WorkflowRunner.new(workflow_file, [target_file], { replay: "step2" })

      # Run the workflow and verify state restoration behavior
      _, err = capture_io { runner.begin! }
      assert_match(/Replaying from step: step2/, err)
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
      runner = Roast::Workflow::WorkflowRunner.new(workflow_file, [target_file], { replay: "#{timestamp}:step3" })

      # Run the workflow
      _, err = capture_io { runner.begin! }
      # Should show replaying with session timestamp
      assert_match(/Replaying from step: step3 \(session: #{timestamp}\)/, err)
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
      runner = Roast::Workflow::WorkflowRunner.new(workflow_file, [target_file], { replay: "nonexistent_step" })

      # Run the workflow and capture output
      _, err = capture_io { runner.begin! }
      assert_match(/Step nonexistent_step not found/, err)
    end
  end

  # restore_workflow_state tests are now in replay_handler_test.rb
  # These tests were moved to test the public API of ReplayHandler class
end
