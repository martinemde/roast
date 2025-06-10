# frozen_string_literal: true

class InfiniteStep < Roast::Workflow::BaseStep
  def call
    # Initialize counter if not present
    workflow.output["execution_count"] ||= 0
    
    # Increment the counter
    workflow.output["execution_count"] += 1
    
    # This step never changes the condition, so it would run forever
    # without a max_iterations limit
    
    "Step executed #{workflow.output['execution_count']} times"
  end
end