# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"
require "roast/workflow/configuration_parser"
require "roast/workflow/base_workflow"
require "roast/resources/none_resource"
require "roast/workflow/workflow_executor"

class RoastWorkflowTargetlessWorkflowTest < ActiveSupport::TestCase
  def setup
    # Create a simple targetless workflow for testing
    @tmpdir = Dir.mktmpdir
    @workflow_path = File.join(@tmpdir, "targetless_workflow.yml")
    File.write(@workflow_path, <<~YAML)
      name: Simple Targetless
      tools: []
      steps:
        - step1: $(echo "Hello from targetless workflow")
    YAML

    @parser = Roast::Workflow::ConfigurationParser.new(@workflow_path)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_executes_workflow_without_a_target
    # The workflow should execute with nil file for targetless workflows
    output = capture_io { @parser.begin! }
    assert_match(/Running targetless workflow/, output.join)
  end

  def test_initializes_base_workflow_with_nil_file
    # Create a temporary targetless workflow file
    Dir.mktmpdir do |tmpdir|
      workflow_file = File.join(tmpdir, "targetless_workflow.yml")
      File.write(workflow_file, <<~YAML)
        name: Targetless Test
        steps:
          - step1: $(echo "Test step")
      YAML

      parser = Roast::Workflow::ConfigurationParser.new(workflow_file)
      configuration = parser.configuration

      # Verify configuration properties
      assert_nil(configuration.target)
      assert_equal("Targetless Test", configuration.name)
      assert_kind_of(Roast::Resources::NoneResource, configuration.resource)
    end
  end
end
