# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class MetadataManagerTest < ActiveSupport::TestCase
      def setup
        @manager = MetadataManager.new
      end

      test "initializes with empty metadata" do
        assert_instance_of ActiveSupport::HashWithIndifferentAccess, @manager.raw_metadata
        assert_empty @manager.raw_metadata
      end

      test "metadata returns DotAccessHash wrapper" do
        assert_instance_of DotAccessHash, @manager.metadata
      end

      test "store and retrieve metadata for steps" do
        @manager.store("step1", "session_id", "abc123")
        @manager.store("step1", "duration", 1500)
        @manager.store("step2", "session_id", "def456")

        assert_equal "abc123", @manager.retrieve("step1", "session_id")
        assert_equal 1500, @manager.retrieve("step1", "duration")
        assert_equal "def456", @manager.retrieve("step2", "session_id")
      end

      test "retrieve returns nil for non-existent keys" do
        assert_nil @manager.retrieve("nonexistent", "key")

        @manager.store("step1", "key1", "value1")
        assert_nil @manager.retrieve("step1", "nonexistent")
      end

      test "for_step returns all metadata for a step" do
        @manager.store("step1", "key1", "value1")
        @manager.store("step1", "key2", "value2")

        step_metadata = @manager.for_step("step1")
        assert_equal({ "key1" => "value1", "key2" => "value2" }, step_metadata)
      end

      test "has_metadata? checks for step existence" do
        refute @manager.has_metadata?("step1")

        @manager.store("step1", "key", "value")
        assert @manager.has_metadata?("step1")
      end

      test "clear_step removes metadata for specific step" do
        @manager.store("step1", "key", "value1")
        @manager.store("step2", "key", "value2")

        @manager.clear_step("step1")

        refute @manager.has_metadata?("step1")
        assert @manager.has_metadata?("step2")
      end

      test "clear removes all metadata" do
        @manager.store("step1", "key", "value1")
        @manager.store("step2", "key", "value2")

        @manager.clear

        refute @manager.has_metadata?("step1")
        refute @manager.has_metadata?("step2")
        assert_empty @manager.raw_metadata
      end

      test "metadata= replaces all metadata" do
        @manager.store("step1", "key", "value1")

        new_metadata = { "step2" => { "key2" => "value2" } }
        @manager.metadata = new_metadata

        refute @manager.has_metadata?("step1")
        assert @manager.has_metadata?("step2")
        assert_equal "value2", @manager.retrieve("step2", "key2")
      end

      test "to_h returns metadata as hash" do
        @manager.store("step1", "key1", "value1")
        @manager.store("step2", "key2", "value2")

        expected = {
          "step1" => { "key1" => "value1" },
          "step2" => { "key2" => "value2" },
        }

        assert_equal expected, @manager.to_h
      end

      test "from_h restores metadata from hash" do
        data = {
          "step1" => { "key1" => "value1" },
          "step2" => { "key2" => "value2" },
        }

        @manager.from_h(data)

        assert_equal "value1", @manager.retrieve("step1", "key1")
        assert_equal "value2", @manager.retrieve("step2", "key2")
      end

      test "from_h handles nil gracefully" do
        @manager.store("step1", "key", "value")
        @manager.from_h(nil)

        # Should keep existing data when given nil
        assert_equal "value", @manager.retrieve("step1", "key")
      end

      test "metadata works with indifferent access" do
        @manager.store("step1", "key", "value")

        # Can access with symbol
        assert_equal "value", @manager.metadata[:step1][:key]

        # Can store with symbol
        @manager.metadata[:step2] = { key: "value2" }
        assert_equal "value2", @manager.retrieve("step2", "key")
      end

      test "dot notation access through metadata method" do
        @manager.store("step1", "session_id", "abc123")
        @manager.store("step1", "config", { "model" => "opus", "temperature" => 0.7 })

        assert_equal "abc123", @manager.metadata.step1.session_id
        assert_equal "opus", @manager.metadata.step1.config.model
        assert_equal 0.7, @manager.metadata.step1.config.temperature
      end

      test "metadata wrapper resets when underlying data changes" do
        # First access creates wrapper
        wrapper1 = @manager.metadata

        # Store modifies data and should reset wrapper
        @manager.store("step1", "key", "value")
        wrapper2 = @manager.metadata

        # Should be different wrapper instances
        refute_same wrapper1, wrapper2

        # But content should reflect the change
        assert_equal "value", wrapper2.step1.key
      end
    end
  end
end
