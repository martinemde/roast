# frozen_string_literal: true

class FunctionalTest < ActiveSupport::TestCase
  class ExecutionResult
    attr_reader :output
    attr_reader :error

    def initialize(output, error)
      @output = output
      @error = error
    end
  end

  def roast(args = [])
    output, err = capture_io do
      Roast::CLI.start(args)
    end

    ExecutionResult.new(output, err)
  end
end
