# frozen_string_literal: true

require "roast/workflow/base_step"

class TestStep < Roast::Workflow::BaseStep
  def call
    "Test step result"
  end
end
EOF < /dev/null