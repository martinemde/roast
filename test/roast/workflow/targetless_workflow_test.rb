# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"
require "roast/workflow/configuration_parser"
require "roast/workflow/base_workflow"
require "roast/resources/none_resource"
require "roast/workflow/workflow_executor"

class RoastWorkflowTargetlessWorkflowTest < ActiveSupport::TestCase
  def setup
    @workflow_path = fixture_file_path("targetless_workflow.yml")
    @parser = Roast::Workflow::ConfigurationParser.new(@workflow_path)
  end

  class MockedExecution < RoastWorkflowTargetlessWorkflowTest
    def test_executes_workflow_without_a_target
      # The workflow should execute with nil file for targetless workflows
      executor = mock("executor")
      executor.expects(:execute_steps)
      Roast::Workflow::WorkflowExecutor.stubs(:new).returns(executor)

      workflow = mock("workflow")
      workflow.stubs(:output_file).returns(nil)
      workflow.stubs(:final_output).returns("")
      workflow.stubs(:session_name).returns("targetless")
      workflow.stubs(:file).returns(nil)
      workflow.stubs(:session_timestamp).returns(nil)
      workflow.stubs(:respond_to?).with(:session_name).returns(true)
      workflow.stubs(:respond_to?).with(:final_output).returns(true)

      Roast::Workflow::BaseWorkflow.expects(:new).with(
        nil,
        has_entries(name: instance_of(String), context_path: instance_of(String)),
      ).returns(workflow)

      capture_io { @parser.begin! }
    end
  end

  class RealBaseWorkflow < RoastWorkflowTargetlessWorkflowTest
    def setup
      super
      @workflow = mock("workflow")
      @workflow.stubs(:output).returns({})
      @workflow.stubs(:final_output).returns("")
      @workflow.stubs(:output_file).returns(nil)
      @workflow.stubs(:output_file=)
      @workflow.stubs(:verbose=)
      # Stub execute_steps to return the workflow
      Roast::Workflow::WorkflowExecutor.any_instance.stubs(:execute_steps).returns(@workflow)
    end

    def test_initializes_base_workflow_with_nil_file
      Roast::Workflow::BaseWorkflow.expects(:new).with do |file, options|
        assert_nil(file)
        assert_kind_of(String, options[:name])
        assert_kind_of(String, options[:context_path])
        assert_kind_of(Roast::Resources::NoneResource, options[:resource])
        true
      end.returns(@workflow)
      @parser.begin!
    end
  end
end
