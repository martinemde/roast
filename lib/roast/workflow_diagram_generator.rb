# frozen_string_literal: true

module Roast
  class WorkflowDiagramGenerator
    def initialize(workflow_config)
      @workflow_config = workflow_config
      @graph = GraphViz.new(:G, type: :digraph)
      @node_counter = 0
      @nodes = {}
    end

    def generate
      configure_graph
      build_graph(@workflow_config.steps)
      output_path = "workflow_diagram.png"
      @graph.output(png: output_path)
      output_path
    end

    private

    def configure_graph
      @graph[:rankdir] = "TB"
      @graph[:fontname] = "Arial"
      @graph.node[:shape] = "box"
      @graph.node[:style] = "rounded,filled"
      @graph.node[:fillcolor] = "lightblue"
      @graph.node[:fontname] = "Arial"
      @graph.edge[:fontname] = "Arial"
    end

    def build_graph(steps, parent_node = nil)
      previous_node = parent_node

      steps.each do |step|
        current_node = process_step(step)

        if previous_node && current_node
          @graph.add_edges(previous_node, current_node)
        end

        previous_node = current_node unless current_node.nil?
      end

      previous_node
    end

    def process_step(step)
      case step
      when String
        create_step_node(step)
      when Hash
        process_control_flow(step)
      end
    end

    def create_step_node(step_name)
      node_id = next_node_id
      label = step_name

      # Check if it's an inline prompt
      @nodes[node_id] = if step_name.start_with?("prompt:")
        @graph.add_nodes(
          node_id,
          label: truncate_label(step_name[7..].strip),
          fillcolor: "lightyellow",
          shape: "note",
        )
      else
        @graph.add_nodes(node_id, label: label)
      end

      @nodes[node_id]
    end

    def process_control_flow(control_flow)
      if control_flow.key?("if") || control_flow.key?("unless")
        process_conditional(control_flow)
      elsif control_flow.key?("each") || control_flow.key?("repeat")
        process_loop(control_flow)
      elsif control_flow.key?("input")
        process_input(control_flow)
      elsif control_flow.key?("proceed?")
        process_proceed(control_flow)
      elsif control_flow.key?("case")
        process_case(control_flow)
      end
    end

    def process_conditional(conditional)
      condition_type = conditional.key?("if") ? "if" : "unless"
      condition = conditional[condition_type]

      # Create diamond decision node
      decision_id = next_node_id
      decision_node = @graph.add_nodes(
        decision_id,
        label: "#{condition_type}: #{condition}",
        shape: "diamond",
        fillcolor: "lightcoral",
      )

      # Process then branch
      if conditional["then"]
        then_steps = Array(conditional["then"])
        if then_steps.any?
          build_graph(then_steps, decision_node)
        end
      end

      # Process else branch
      if conditional["else"]
        else_steps = Array(conditional["else"])
        if else_steps.any?
          build_graph(else_steps, decision_node)
        end
      end

      decision_node
    end

    def process_loop(loop_control)
      loop_type = loop_control.key?("each") ? "each" : "repeat"
      loop_value = loop_control[loop_type]

      # Create loop node
      loop_id = next_node_id
      loop_label = loop_type == "each" ? "each: #{loop_value}" : "repeat: #{loop_value}"
      loop_node = @graph.add_nodes(
        loop_id,
        label: loop_label,
        shape: "box3d",
        fillcolor: "lightgreen",
      )

      # Process loop body
      if loop_control["do"]
        loop_steps = Array(loop_control["do"])
        if loop_steps.any?
          last_loop_node = build_graph(loop_steps, loop_node)
          # Add back edge to show loop
          @graph.add_edges(last_loop_node, loop_node, style: "dashed", label: "loop")
        end
      end

      loop_node
    end

    def process_input(input_control)
      input_id = next_node_id
      label = input_control["input"]
      input_node = @graph.add_nodes(
        input_id,
        label: "input: #{label}",
        shape: "parallelogram",
        fillcolor: "lightgray",
      )
      input_node
    end

    def process_proceed(proceed_control)
      proceed_id = next_node_id
      proceed_node = @graph.add_nodes(
        proceed_id,
        label: "proceed?",
        shape: "diamond",
        fillcolor: "orange",
      )

      # Process do branch if present
      if proceed_control["do"]
        proceed_steps = Array(proceed_control["do"])
        if proceed_steps.any?
          build_graph(proceed_steps, proceed_node)
        end
      end

      proceed_node
    end

    def process_case(case_control)
      case_id = next_node_id
      case_node = @graph.add_nodes(
        case_id,
        label: "case: #{case_control["case"]}",
        shape: "diamond",
        fillcolor: "lavender",
      )

      # Process when branches
      case_control["when"].each do |condition, steps|
        when_steps = Array(steps)
        next if when_steps.none?

        first_when_node = process_step(when_steps.first)
        @graph.add_edges(case_node, first_when_node, label: condition.to_s)

        if when_steps.length > 1
          build_graph(when_steps[1..], first_when_node)
        end
      end

      case_node
    end

    def next_node_id
      @node_counter += 1
      "node_#{@node_counter}"
    end

    def truncate_label(text, max_length = 50)
      return text if text.length <= max_length

      "#{text[0...max_length]}..."
    end
  end
end
