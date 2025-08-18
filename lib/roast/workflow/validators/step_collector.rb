# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Collects and caches all steps from a workflow configuration
      class StepCollector
        def initialize(parsed_yaml)
          @parsed_yaml = parsed_yaml
          @all_steps = nil
        end

        def all_steps
          @all_steps ||= collect_all_steps(@parsed_yaml)
        end

        private

        def collect_all_steps(config, steps = [])
          # Recursively collect all steps from the configuration
          ["steps", "pre_processing", "post_processing"].each do |key|
            if config[key]
              steps.concat(extract_steps_from_array(config[key]))
            end
          end
          steps
        end

        def extract_steps_from_array(steps_array, collected = [])
          steps_array.each do |step|
            case step
            when String
              collected << step
            when Hash
              if step["steps"]
                collected.concat(extract_steps_from_array(step["steps"]))
              end
              # Handle conditional steps
              ["then", "else", "true", "false"].each do |branch|
                if step[branch]
                  collected.concat(extract_steps_from_array(step[branch]))
                end
              end
              # Handle case/when steps
              step["when"]&.each_value do |when_steps|
                collected.concat(extract_steps_from_array(when_steps))
              end
            when Array
              collected.concat(extract_steps_from_array(step))
            end
          end
          collected
        end
      end
    end
  end
end
