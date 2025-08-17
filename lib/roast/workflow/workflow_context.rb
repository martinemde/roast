# typed: false
# frozen_string_literal: true

module Roast
  module Workflow
    # Encapsulates common workflow execution context parameters
    # Reduces data clump anti-pattern by grouping related parameters
    class WorkflowContext
      attr_reader :workflow, :config_hash, :context_path

      # Initialize the workflow context
      # @param workflow [BaseWorkflow] The workflow instance
      # @param config_hash [Hash] The workflow configuration hash
      # @param context_path [String] The context directory path
      def initialize(workflow:, config_hash:, context_path:)
        @workflow = workflow
        @config_hash = config_hash
        @context_path = context_path
        freeze
      end

      # Create a new context with updated workflow
      # @param new_workflow [BaseWorkflow] The new workflow instance
      # @return [WorkflowContext] A new context with the updated workflow
      def with_workflow(new_workflow)
        self.class.new(
          workflow: new_workflow,
          config_hash: config_hash,
          context_path: context_path,
        )
      end

      # Check if the workflow has a resource
      # @return [Boolean] true if workflow responds to resource and has one
      def has_resource?
        workflow.respond_to?(:resource) && workflow.resource
      end

      # Get the resource type from the workflow
      # @return [Symbol, nil] The resource type or nil
      def resource_type
        has_resource? ? workflow.resource.type : nil
      end

      # Get configuration for a specific step
      # @param step_name [String] The name of the step
      # @return [Hash] The step configuration or empty hash
      def step_config(step_name)
        config_hash[step_name] || {}
      end

      # Check if a step should exit on error
      # @param step_name [String] The name of the step
      # @return [Boolean] true if the step should exit on error (default true)
      def exit_on_error?(step_name)
        config = step_config(step_name)
        config.is_a?(Hash) ? config.fetch("exit_on_error", true) : true
      end
    end
  end
end
