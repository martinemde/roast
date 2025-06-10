# frozen_string_literal: true

class ProcessItem < Roast::Workflow::BaseStep
  def call
    # Initialize processed items array if not present
    workflow.output["processed_items"] ||= []
    
    # Get the current item from the workflow
    # (The EachStep would dynamically add this method)
    current_item = workflow.current_item
    
    # Record that we processed this item
    workflow.output["processed_items"] << current_item
    
    "Processed item: #{current_item}"
  end
end