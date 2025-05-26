# frozen_string_literal: true

require "active_support/notifications"
require "roast/workflow/replay_handler"
require "roast/workflow/workflow_executor"
require "roast/workflow/output_handler"
require "roast/workflow/base_workflow"

module Roast
  module Workflow
    # Handles running workflows for files/targets and orchestrating execution
    class WorkflowRunner
      def initialize(configuration, options = {})
        @configuration = configuration
        @options = options
        @output_handler = OutputHandler.new
        @workflow_results = []
      end

      def run_for_files(files)
        if @configuration.has_target?
          $stderr.puts "WARNING: Ignoring target parameter because files were provided: #{@configuration.target}"
        end

        # Execute pre-processing steps once before any targets
        if @configuration.pre_processing.any?
          $stderr.puts "Running pre-processing steps..."
          run_pre_processing
        end

        # Execute main workflow for each file
        files.each do |file|
          $stderr.puts "Running workflow for file: #{file}"
          run_single_workflow(file.strip)
        end

        # Execute post-processing steps once after all targets
        if @configuration.post_processing.any?
          $stderr.puts "Running post-processing steps..."
          run_post_processing
        end
      end

      def run_for_targets
        # Execute pre-processing steps once before any targets
        if @configuration.pre_processing.any?
          $stderr.puts "Running pre-processing steps..."
          run_pre_processing
        end

        # Execute main workflow for each target
        @configuration.target.lines.each do |file|
          $stderr.puts "Running workflow for file: #{file.strip}"
          run_single_workflow(file.strip)
        end

        # Execute post-processing steps once after all targets
        if @configuration.post_processing.any?
          $stderr.puts "Running post-processing steps..."
          run_post_processing
        end
      end

      def run_targetless
        $stderr.puts "Running targetless workflow"

        # Execute pre-processing steps
        if @configuration.pre_processing.any?
          $stderr.puts "Running pre-processing steps..."
          run_pre_processing
        end

        # Execute main workflow
        run_single_workflow(nil)

        # Execute post-processing steps
        if @configuration.post_processing.any?
          $stderr.puts "Running post-processing steps..."
          run_post_processing
        end
      end

      # Public for backward compatibility with tests
      def execute_workflow(workflow)
        steps = @configuration.steps

        # Handle replay option
        if @options[:replay]
          replay_handler = ReplayHandler.new(workflow)
          steps = replay_handler.process_replay(steps, @options[:replay])
        end

        # Execute the steps
        executor = WorkflowExecutor.new(workflow, @configuration.config_hash, @configuration.context_path)
        executor.execute_steps(steps)

        $stderr.puts "🔥🔥🔥 ROAST COMPLETE! 🔥🔥🔥"

        # Save outputs
        @output_handler.save_final_output(workflow)
        @output_handler.write_results(workflow)
      end

      private

      def run_single_workflow(file)
        workflow = create_workflow(file)
        execute_workflow(workflow)

        # Store workflow results for post-processing
        @workflow_results << {
          file: file,
          state: workflow.state.dup,
          final_output: workflow.final_output,
          transcript: workflow.transcript.dup,
        }
      end

      def run_pre_processing
        # Create a workflow for pre-processing (no specific file target)
        workflow = create_workflow(nil)

        # Execute pre-processing steps
        executor = WorkflowExecutor.new(workflow, @configuration.config_hash, @configuration.context_path, phase: :pre_processing)
        executor.execute_steps(@configuration.pre_processing)

        # Store pre-processing results in shared state
        @pre_processing_results = workflow.state
      end

      def run_post_processing
        # Create a workflow for post-processing with access to all results
        workflow = create_workflow(nil)

        # Make pre-processing results and all workflow results available
        workflow.state[:pre_processing_results] = @pre_processing_results if @pre_processing_results
        workflow.state[:all_workflow_results] = collect_all_workflow_results

        # Execute post-processing steps
        executor = WorkflowExecutor.new(workflow, @configuration.config_hash, @configuration.context_path, phase: :post_processing)
        executor.execute_steps(@configuration.post_processing)

        # Save post-processing outputs
        @output_handler.save_final_output(workflow)
        @output_handler.write_results(workflow)
      end

      def collect_all_workflow_results
        @workflow_results
      end

      def create_workflow(file)
        BaseWorkflow.new(
          file,
          name: @configuration.basename,
          context_path: @configuration.context_path,
          resource: @configuration.resource,
          session_name: @configuration.name,
          configuration: @configuration,
        ).tap do |workflow|
          workflow.output_file = @options[:output] if @options[:output].present?
          workflow.verbose = @options[:verbose] if @options[:verbose].present?
          workflow.concise = @options[:concise] if @options[:concise].present?
          workflow.pause_step_name = @options[:pause] if @options[:pause].present?
        end
      end
    end
  end
end
