# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class StepExecutorRegistryTest < ActiveSupport::TestCase
      class TestExecutor
        def initialize(workflow_executor)
          @workflow_executor = workflow_executor
        end
      end

      class AnotherTestExecutor
        def initialize(workflow_executor)
          @workflow_executor = workflow_executor
        end
      end

      class CustomStep; end
      class InheritedStep < CustomStep; end

      def setup
        @workflow_executor = mock("workflow_executor")
        @workflow_executor.stubs(:workflow).returns(mock("workflow"))
        @workflow_executor.stubs(:config_hash).returns({})

        # Store the current state to restore later
        @original_executors = StepExecutorRegistry.registered_executors.dup
        @original_defaults_registered = StepExecutorFactory.instance_variable_get(:@defaults_registered)

        # Clear the registry before each test
        StepExecutorRegistry.clear!
      end

      def teardown
        # Restore the original state properly
        StepExecutorRegistry.clear!

        # Reset the defaults flag to ensure defaults get re-registered
        StepExecutorFactory.instance_variable_set(:@defaults_registered, false)

        # Ensure defaults are registered (this will set @defaults_registered = true)
        StepExecutorFactory.ensure_defaults_registered

        # Then add any additional executors that were originally registered
        @original_executors.each do |klass, executor_class|
          # Skip re-registering defaults since they're already registered above
          unless [Hash, Array, String].include?(klass)
            StepExecutorRegistry.register(klass, executor_class)
          end
        end
      end

      def test_register_and_retrieve_executor
        StepExecutorRegistry.register(String, TestExecutor)

        executor = StepExecutorRegistry.for("test", @workflow_executor)
        assert_instance_of(TestExecutor, executor)
      end

      def test_register_multiple_executors
        StepExecutorRegistry.register(String, TestExecutor)
        StepExecutorRegistry.register(Hash, AnotherTestExecutor)

        string_executor = StepExecutorRegistry.for("test", @workflow_executor)
        hash_executor = StepExecutorRegistry.for({}, @workflow_executor)

        assert_instance_of(TestExecutor, string_executor)
        assert_instance_of(AnotherTestExecutor, hash_executor)
      end

      def test_raises_error_for_unknown_step_type
        error = assert_raises(StepExecutorRegistry::UnknownStepTypeError) do
          StepExecutorRegistry.for(Object.new, @workflow_executor)
        end

        assert_match(/No executor registered for step type: Object/, error.message)
      end

      def test_register_with_matcher
        # Use a custom object type that won't conflict with default registrations
        custom_step = Struct.new(:type).new("custom")

        matcher = ->(step) { step.respond_to?(:type) && step.type == "custom" }
        StepExecutorRegistry.register_with_matcher(matcher, TestExecutor)

        executor = StepExecutorRegistry.for(custom_step, @workflow_executor)
        assert_instance_of(TestExecutor, executor)
      end

      def test_class_registration_takes_precedence_over_matcher
        StepExecutorRegistry.register(String, AnotherTestExecutor)

        matcher = ->(step) { step.is_a?(String) && step.start_with?("special:") }
        StepExecutorRegistry.register_with_matcher(matcher, TestExecutor)

        regular_executor = StepExecutorRegistry.for("regular", @workflow_executor)
        special_executor = StepExecutorRegistry.for("special:step", @workflow_executor)

        # Class registration takes precedence, so both get AnotherTestExecutor
        assert_instance_of(AnotherTestExecutor, regular_executor)
        assert_instance_of(AnotherTestExecutor, special_executor)
      end

      def test_inheritance_lookup
        StepExecutorRegistry.register(CustomStep, TestExecutor)

        executor = StepExecutorRegistry.for(InheritedStep.new, @workflow_executor)
        assert_instance_of(TestExecutor, executor)
      end

      def test_clear_removes_all_registrations
        StepExecutorRegistry.register(String, TestExecutor)
        StepExecutorRegistry.register(Hash, AnotherTestExecutor)

        StepExecutorRegistry.clear!

        assert_raises(StepExecutorRegistry::UnknownStepTypeError) do
          StepExecutorRegistry.for("test", @workflow_executor)
        end
      end

      def test_registered_executors_returns_copy
        # Use a unique class that won't conflict with defaults
        custom_class = Class.new
        StepExecutorRegistry.register(custom_class, TestExecutor)

        # Get initial snapshot
        executors_before = StepExecutorRegistry.registered_executors
        original_count = executors_before.size

        # Verify our registration is there
        assert_equal(TestExecutor, executors_before[custom_class])

        # Modify the returned copy by adding a new entry
        modification_class = Class.new
        executors_before[modification_class] = AnotherTestExecutor

        # Verify the original registry wasn't modified
        executors_after = StepExecutorRegistry.registered_executors
        refute(executors_after.key?(modification_class), "Registry should not contain modification_class key after modifying the copy")
        assert_equal(TestExecutor, executors_after[custom_class], "Original registration should be unchanged")

        # The registry should have the same number of entries as before (or possibly more if defaults were re-registered)
        # but it should NOT have our modification
        assert_operator(executors_after.size, :>=, original_count, "Registry size should not decrease")
        refute(executors_after.key?(modification_class), "Registry should not contain our modification")
      end

      def test_executor_receives_workflow_executor_in_constructor
        StepExecutorRegistry.register(String, TestExecutor)

        TestExecutor.expects(:new).with(@workflow_executor).returns(mock("executor"))

        StepExecutorRegistry.for("test", @workflow_executor)
      end

      def test_multiple_matchers_first_match_wins
        @workflow_executor.stubs(:workflow).returns(mock("workflow"))
        @workflow_executor.stubs(:config_hash).returns({})

        matcher1 = ->(step) { step.is_a?(Symbol) && step.to_s.include?("test") }
        matcher2 = ->(step) { step.is_a?(Symbol) && step.to_s.include?("es") }

        StepExecutorRegistry.register_with_matcher(matcher1, TestExecutor)
        StepExecutorRegistry.register_with_matcher(matcher2, AnotherTestExecutor)

        executor = StepExecutorRegistry.for(:test, @workflow_executor)
        assert_instance_of(TestExecutor, executor)
      end

      def test_class_registration_overrides_previous
        StepExecutorRegistry.register(String, TestExecutor)
        StepExecutorRegistry.register(String, AnotherTestExecutor)

        executor = StepExecutorRegistry.for("test", @workflow_executor)
        assert_instance_of(AnotherTestExecutor, executor)
      end
    end
  end
end
