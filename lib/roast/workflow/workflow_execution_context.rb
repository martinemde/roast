# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Roast
  module Workflow
    # Manages execution context across pre-processing, target workflows, and post-processing phases
    class WorkflowExecutionContext
      attr_reader :pre_processing_output, :target_outputs

      def initialize
        @pre_processing_output = OutputManager.new
        @target_outputs = {}
      end

      # Add output from a target workflow execution
      def add_target_output(target, output_manager)
        target_key = generate_target_key(target)
        @target_outputs[target_key] = output_manager
      end

      # Get all data as a hash for post-processing
      def to_h
        {
          pre_processing: @pre_processing_output.to_h,
          targets: @target_outputs.transform_values(&:to_h),
        }
      end

      private

      def generate_target_key(target)
        return "default" unless target

        target.to_s.parameterize
      end
    end
  end
end
