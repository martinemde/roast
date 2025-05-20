# frozen_string_literal: true

module Roast
  module Workflow
    # Executes steps for each item in a collection
    class EachStep < BaseIterationStep
      attr_reader :collection_expr, :variable_name

      def initialize(workflow, collection_expr:, variable_name:, steps:, **kwargs)
        super(workflow, steps: steps, **kwargs)
        @collection_expr = collection_expr
        @variable_name = variable_name
      end

      def call
        # Resolve the collection expression
        collection = resolve_collection

        unless collection.respond_to?(:each)
          $stderr.puts "Error: Collection '#{@collection_expr}' is not iterable"
          raise ArgumentError, "Collection '#{@collection_expr}' is not iterable"
        end

        results = []
        $stderr.puts "Starting each loop over collection with #{collection.size} items"

        # Iterate over the collection
        collection.each_with_index do |item, index|
          $stderr.puts "Each loop iteration #{index + 1} with #{@variable_name}=#{item.inspect}"

          # Create a context with the current item as a variable
          define_iteration_variable(item)

          # Execute the nested steps
          step_results = execute_nested_steps(@steps, workflow)
          results << step_results

          # Save state after each iteration if the workflow supports it
          save_iteration_state(index, item) if workflow.respond_to?(:session_name) && workflow.session_name
        end

        $stderr.puts "Each loop completed with #{collection.size} iterations"
        results
      end

      private

      def resolve_collection
        # Remove surrounding {{ }} if present
        expr = @collection_expr.strip
        if expr.start_with?("{{") && expr.end_with?("}}")
          expr = expr[2...-2].strip
        end

        begin
          # Evaluate the expression in the workflow's context
          result = workflow.instance_eval(expr)

          # Convert to array if it's not already an enumerable
          if !result.respond_to?(:each)
            $stderr.puts "Warning: Collection '#{expr}' is not an enumerable, converting to array"
            [result]
          else
            result
          end
        rescue => e
          $stderr.puts "Error resolving collection '#{expr}': #{e.message}"
          raise
        end
      end

      def define_iteration_variable(value)
        # Set the variable in the workflow's context
        workflow.instance_variable_set("@#{@variable_name}", value)

        # Define a getter method for the variable
        var_name = @variable_name.to_sym
        workflow.singleton_class.class_eval do
          attr_reader(var_name)
        end

        # Make the variable accessible in the output hash
        workflow.output[@variable_name] = value if workflow.respond_to?(:output)
      end

      def save_iteration_state(index, item)
        state_repository = FileStateRepository.new

        # Save the current iteration state
        state_data = {
          step_name: name,
          iteration_index: index,
          current_item: item,
          output: workflow.respond_to?(:output) ? workflow.output.clone : {},
          transcript: workflow.respond_to?(:transcript) ? workflow.transcript.map(&:itself) : [],
        }

        state_repository.save_state(workflow, "#{name}_item_#{index}", state_data)
      rescue => e
        # Don't fail the workflow if state saving fails
        $stderr.puts "Warning: Failed to save iteration state: #{e.message}"
      end
    end
  end
end
