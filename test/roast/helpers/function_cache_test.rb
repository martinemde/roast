# frozen_string_literal: true

require "test_helper"

module Roast
  module Helpers
    class FunctionCacheTest < ActiveSupport::TestCase
      def test_for_workflow_creates_cache_instance
        workflow_name = "test_workflow"
        workflow_path = "/path/to/workflow.yml"

        with_fake_dot_roast_root do
          cache1 = FunctionCache.for_workflow(workflow_name, workflow_path)
          cache2 = FunctionCache.for_workflow(workflow_name, workflow_path)

          assert_instance_of(ActiveSupport::Cache::FileStore, cache1)
          assert_instance_of(ActiveSupport::Cache::FileStore, cache2)
        end
      end

      def test_for_namespace_returns_file_store_cache_instance
        with_fake_dot_roast_root do
          cache = FunctionCache.for_namespace("test_namespace")
          assert_instance_of(ActiveSupport::Cache::FileStore, cache)
        end
      end

      def test_for_namespace_creates_cache_subdirectory
        with_fake_dot_roast_root do |tmpdir|
          namespace = "test_namespace"
          FunctionCache.for_namespace(namespace)

          # DotRoast.ensure_subdir should have been called and cache subdir created
          cache_dir = File.join(tmpdir, "cache")
          assert(File.directory?(cache_dir))
          assert(File.exist?(File.join(cache_dir, ".gitignore")))
        end
      end

      def test_namespace_from_workflow_returns_sanitized_name_and_sha
        workflow_name = "Test Workflow"
        workflow_path = "/path/to/workflow.yml"
        expected_namespace = "test_workflow_#{Digest::MD5.hexdigest(workflow_path).first(4)}"
        assert_equal(expected_namespace, FunctionCache.namespace_from_workflow(workflow_name, workflow_path))
      end

      private

      def with_fake_dot_roast_root
        Dir.mktmpdir do |tmpdir|
          Roast::DotRoast.stubs(:root).returns(tmpdir)
          yield(tmpdir)
        end
      end
    end
  end
end
