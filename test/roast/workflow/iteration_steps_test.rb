# frozen_string_literal: true

require "test_helper"
require "roast/workflow/repeat_step"
require "roast/workflow/each_step"

module Roast
  module Workflow
    class IterationStepsTest < Minitest::Test
      include FixtureHelpers

      def setup
        @workflow = BaseWorkflow.new(nil, name: "test_workflow")
        @workflow.output = {}
        @context_path = File.expand_path("../../fixtures/steps/iteration_test", __dir__)
      end

      def test_repeat_step_with_condition_met
        # Create a repeat step that will terminate after condition is met
        repeat_step = RepeatStep.new(
          @workflow,
          steps: ["increment_counter", "check_counter"],
          until_condition: "output['condition_met'] == true",
          max_iterations: 10,
          name: "repeat_until_condition_met",
          context_path: @context_path,
        )

        # Execute the repeat step
        repeat_step.call

        # Verify the step executed until the condition was met (3 iterations)
        assert_equal(3, @workflow.output["counter"])
        assert_equal(true, @workflow.output["condition_met"])
      end

      def test_repeat_step_with_max_iterations_reached
        # Create a repeat step with a condition that won't be met
        repeat_step = RepeatStep.new(
          @workflow,
          steps: ["infinite_step"],
          until_condition: "false", # Never satisfied
          max_iterations: 5,        # But limited to 5 iterations
          name: "repeat_with_limit",
          context_path: @context_path,
        )

        # Execute the repeat step
        repeat_step.call

        # Verify the step executed the maximum number of times
        assert_equal(5, @workflow.output["execution_count"])
      end

      def test_each_step
        # Setup test data
        @workflow.output["test_items"] = [1, 2, 3, 4, 5]

        # Add the getter method for current_item that our test steps expect
        class << @workflow
          attr_reader :current_item
        end

        # Create an each step
        each_step = EachStep.new(
          @workflow,
          collection_expr: "output['test_items']",
          variable_name: "current_item",
          steps: ["process_item"],
          name: "each_item",
          context_path: @context_path,
        )

        # Execute the each step
        each_step.call

        # Verify each item was processed
        assert_equal([1, 2, 3, 4, 5], @workflow.output["processed_items"])
      end

      def test_each_step_with_empty_collection
        # Setup an empty collection
        @workflow.output["empty_items"] = []

        # Add the getter method for current_item that our test steps expect
        class << @workflow
          attr_reader :current_item
        end

        # Flag to track if any steps were executed
        @workflow.output["steps_executed"] = false

        # Create a step that will set the flag if executed
        def @workflow.would_fail_if_executed
          # This should never be called for an empty collection
          @output["steps_executed"] = true
          "This step should not be executed"
        end

        # Create an each step with an empty collection
        each_step = EachStep.new(
          @workflow,
          collection_expr: "output['empty_items']",
          variable_name: "current_item",
          steps: ["would_fail_if_executed"],
          name: "each_empty",
          context_path: @context_path,
        )

        # Execute the each step
        results = each_step.call

        # Verify no steps were executed
        assert_equal(false, @workflow.output["steps_executed"])
        assert_equal(0, results.size)
      end
    end
  end
end
