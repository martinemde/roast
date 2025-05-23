# frozen_string_literal: true

class IncrementCounter < Roast::Workflow::BaseStep
      def call
        # Initialize counter if not present
        workflow.output["counter"] ||= 0
        
        # Increment the counter
        workflow.output["counter"] += 1
        
        "Counter incremented to #{workflow.output['counter']}"
      end
end