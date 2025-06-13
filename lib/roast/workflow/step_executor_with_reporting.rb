# frozen_string_literal: true

module Roast
  module Workflow
    # Decorator that adds token consumption reporting to step execution
    class StepExecutorWithReporting
      def initialize(base_executor, context, output: $stderr)
        @base_executor = base_executor
        @context = context
        @reporter = StepCompletionReporter.new(output: output)
        @name_extractor = StepNameExtractor.new
      end

      def execute(step, options = {})
        # Track tokens before execution
        tokens_before = @context.workflow.context_manager&.total_tokens || 0
        
        # Execute the step
        result = @base_executor.execute(step, options)
        
        # Report token consumption after successful execution
        tokens_after = @context.workflow.context_manager&.total_tokens || 0
        tokens_consumed = tokens_after - tokens_before
        
        step_type = StepTypeResolver.resolve(step, @context)
        step_name = @name_extractor.extract(step, step_type)
        @reporter.report(step_name, tokens_consumed, tokens_after)
        
        result
      end

      # Delegate all other methods to the base executor
      def method_missing(method, *args, **kwargs, &block)
        if @base_executor.respond_to?(method)
          @base_executor.send(method, *args, **kwargs, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        @base_executor.respond_to?(method, include_private) || super
      end
    end
  end
end