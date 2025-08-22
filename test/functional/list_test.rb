# frozen_string_literal: true

require "test_helper"

class ListTest < FunctionalTest
  test "lists workflows visible to roast" do
    in_sandbox(with_workflow: :simple) do
      assert_output Regexp.new(Regexp.escape("simple (from project)")) do
        roast("list")
      end
    end
  end

  test "outputs error if no roast directory found" do
    assert_cli_error(%r{No roast/ directory found in current path}) do
      roast("list")
    end
  end

  test "outputs error if no workflow files found" do
    assert_cli_error(%r{No workflow.yml files found in roast/ directory}) do
      in_sandbox do
        roast("list")
      end
    end
  end
end
