# frozen_string_literal: true

class CheckCounter < Roast::Workflow::BaseStep
  def call
    # Check if counter should terminate the loop
    if workflow.output["counter"] && workflow.output["counter"] == 3
      workflow.output["condition_met"] = true
    end
    
    "Counter checked, value is #{workflow.output['counter'] || 0}"
  end
end