# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class BaseStepJsonTest < ActiveSupport::TestCase
      setup do
        @workflow = BaseWorkflow.new(nil, name: "test_workflow")
        @workflow.output = {}
      end

      test "JSON array response returns first element when json is true" do
        step = BaseStep.new(@workflow, name: "test_step")
        step.json = true

        # Create a JSON array response
        json_array = [
          { "id" => 1, "name" => "Item 1" },
          { "id" => 2, "name" => "Item 2" },
        ]

        # Stub workflow methods
        @workflow.stub(:openai?, false) do
          @workflow.stub(:chat_completion, json_array) do
            # Stub read_sidecar_prompt to return a simple prompt
            step.stub(:read_sidecar_prompt, "Test prompt") do
              result = step.call

              # Result should be the first element of the array
              assert_instance_of Hash, result
              assert_equal 1, result["id"]
              assert_equal "Item 1", result["name"]
            end
          end
        end
      end

      test "Non-JSON array response is joined when json is false" do
        step = BaseStep.new(@workflow, name: "test_step")
        step.json = false

        # Create a string array response
        string_array = ["Line 1", "Line 2", "Line 3"]

        @workflow.stub(:openai?, false) do
          @workflow.stub(:chat_completion, string_array) do
            step.stub(:read_sidecar_prompt, "Test prompt") do
              result = step.call

              # Result should be joined
              assert_instance_of String, result
              assert_equal "Line 1\nLine 2\nLine 3", result
            end
          end
        end
      end

      test "JSON array with nil first element returns nil" do
        step = BaseStep.new(@workflow, name: "test_step")
        step.json = true

        # Array with nil as first element
        json_array = [
          nil,
          { "id" => 2, "name" => "Item 2" },
          { "id" => 3, "name" => "Item 3" },
        ]

        @workflow.stub(:openai?, false) do
          @workflow.stub(:chat_completion, json_array) do
            step.stub(:read_sidecar_prompt, "Test prompt") do
              result = step.call

              # Should return nil since flatten.first returns the first element
              assert_nil result
            end
          end
        end
      end

      test "Nested JSON array response flattens and returns first element" do
        step = BaseStep.new(@workflow, name: "test_step")
        step.json = true

        # Create a nested array response
        json_array = [
          [
            { "id" => 1, "name" => "Nested Item 1" },
            { "id" => 2, "name" => "Nested Item 2" },
          ],
          { "id" => 3, "name" => "Item 3" },
        ]

        @workflow.stub(:openai?, false) do
          @workflow.stub(:chat_completion, json_array) do
            step.stub(:read_sidecar_prompt, "Test prompt") do
              result = step.call

              # Should flatten and return the first element
              assert_instance_of Hash, result
              assert_equal 1, result["id"]
              assert_equal "Nested Item 1", result["name"]
            end
          end
        end
      end

      test "Hash response is preserved when json is true" do
        step = BaseStep.new(@workflow, name: "test_step")
        step.json = true

        # Create a hash response
        json_hash = {
          "status" => "success",
          "data" => { "count" => 42 },
          "items" => ["a", "b", "c"],
        }

        @workflow.stub(:openai?, false) do
          @workflow.stub(:chat_completion, json_hash) do
            step.stub(:read_sidecar_prompt, "Test prompt") do
              result = step.call

              # Result should be the hash itself
              assert_instance_of Hash, result
              assert_equal "success", result["status"]
              assert_equal 42, result["data"]["count"]
              assert_equal ["a", "b", "c"], result["items"]
            end
          end
        end
      end
    end
  end
end
