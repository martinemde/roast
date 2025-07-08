# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class MetadataManagerTest < ActiveSupport::TestCase
      def setup
        @manager = MetadataManager.new
      end

      def test_initializes_with_empty_metadata
        assert_instance_of(DotAccessHash, @manager.metadata)
        assert_empty(@manager.raw_metadata)
      end

      def test_metadata_setter_converts_hash_to_indifferent_access
        regular_hash = { "key" => "value" }
        @manager.metadata = regular_hash

        assert_instance_of(ActiveSupport::HashWithIndifferentAccess, @manager.raw_metadata)
        assert_equal("value", @manager.metadata[:key])
        assert_equal("value", @manager.metadata["key"])
      end

      def test_metadata_setter_preserves_indifferent_access
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(key: "value")
        @manager.metadata = indifferent_hash

        assert_same(indifferent_hash, @manager.raw_metadata)
      end

      def test_metadata_supports_dot_notation_access
        @manager.metadata = {
          simple: "value",
          nested: {
            level1: {
              level2: "deep",
            },
          },
        }

        assert_equal("value", @manager.metadata.simple)
        assert_equal("deep", @manager.metadata.nested.level1.level2)
      end

      def test_to_h_returns_state_snapshot
        @manager.metadata["step1"] = { "session_id" => "abc123" }
        @manager.metadata["step2"] = { "duration" => 1500 }

        snapshot = @manager.to_h
        assert_equal({ "step1" => { "session_id" => "abc123" }, "step2" => { "duration" => 1500 } }, snapshot)
      end

      def test_from_h_restores_state
        data = {
          "step1" => { "session_id" => "restored123" },
          "step2" => { "tokens" => 500 },
        }

        @manager.from_h(data)
        assert_equal("restored123", @manager.metadata["step1"]["session_id"])
        assert_equal(500, @manager.metadata["step2"]["tokens"])
      end

      def test_from_h_handles_nil_gracefully
        @manager.from_h(nil)
        assert_empty(@manager.metadata)
      end

      def test_from_h_handles_partial_data
        @manager.metadata["existing"] = { "key" => "value" }
        @manager.from_h({ "step1" => { "session_id" => "new123" } })

        assert_equal("new123", @manager.metadata["step1"]["session_id"])
        # NOTE: from_h replaces the entire metadata hash
        assert_nil(@manager.metadata["existing"])
      end

      def test_serialization_roundtrip_preserves_data
        @manager.metadata["step1"] = { "session_id" => "abc123" }
        @manager.metadata["step2"] = { "tokens" => 500 }

        serialized = @manager.to_h
        new_manager = MetadataManager.new
        new_manager.from_h(serialized)

        assert_equal("abc123", new_manager.metadata["step1"]["session_id"])
        assert_equal(500, new_manager.metadata["step2"]["tokens"])
      end
    end
  end
end
