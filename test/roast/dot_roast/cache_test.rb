# frozen_string_literal: true

require "test_helper"

module Roast
  class DotRoast
    class CacheTest < ActiveSupport::TestCase
      def test_path_returns_cache_directory_under_config_root
        with_fake_dot_roast_dir do |dot_roast_dir|
          expected_path = File.join(dot_roast_dir, "cache")
          assert_equal(expected_path, Roast::DotRoast::Cache.path)
        end
      end

      def test_ensure_exists_creates_cache_directory
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          refute(File.directory?(cache_dir))

          Roast::DotRoast::Cache.ensure_exists

          assert(File.directory?(cache_dir))
        end
      end

      def test_ensure_exists_does_not_fail_if_directory_already_exists
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          FileUtils.mkdir_p(cache_dir)
          assert(File.directory?(cache_dir))

          assert_nothing_raised do
            Roast::DotRoast::Cache.ensure_exists
          end

          assert(File.directory?(cache_dir))
        end
      end

      def test_gitignore_path_returns_correct_path
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          expected_path = File.join(cache_dir, ".gitignore")
          assert_equal(expected_path, Roast::DotRoast::Cache.gitignore_path)
        end
      end

      def test_ensure_gitignore_exists_creates_gitignore_file
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          FileUtils.mkdir_p(cache_dir)
          gitignore_path = File.join(cache_dir, ".gitignore")
          refute(File.exist?(gitignore_path))

          Roast::DotRoast::Cache.ensure_gitignore_exists

          assert(File.exist?(gitignore_path))
          assert_equal("*", File.read(gitignore_path))
        end
      end

      def test_ensure_gitignore_exists_does_not_overwrite_existing_file
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          FileUtils.mkdir_p(cache_dir)
          gitignore_path = File.join(cache_dir, ".gitignore")
          File.write(gitignore_path, "custom content")

          Roast::DotRoast::Cache.ensure_gitignore_exists

          assert_equal("custom content", File.read(gitignore_path))
        end
      end

      def test_for_namespace_ensures_directory_and_gitignore_exist
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache_dir = File.join(dot_roast_dir, "cache")
          refute(File.directory?(cache_dir))
          gitignore_path = File.join(cache_dir, ".gitignore")
          refute(File.exist?(gitignore_path))

          cache = Roast::DotRoast::Cache.for_namespace("test_namespace")

          assert(File.directory?(cache_dir))
          assert(File.exist?(gitignore_path))
          assert_equal("*", File.read(gitignore_path))
          assert_instance_of(ActiveSupport::Cache::FileStore, cache)
        end
      end

      def test_for_namespace_returns_file_store_cache_instance
        with_fake_dot_roast_dir do |_dot_roast_dir|
          cache = Roast::DotRoast::Cache.for_namespace("test_namespace")

          assert_instance_of(ActiveSupport::Cache::FileStore, cache)
        end
      end

      def test_for_namespace_sets_correct_cache_path
        with_fake_dot_roast_dir do |dot_roast_dir|
          cache = Roast::DotRoast::Cache.for_namespace("test_namespace")
          expected_path = File.join(dot_roast_dir, "cache", "test_namespace")

          # Access the cache_path through the FileStore's options
          assert_equal(expected_path, cache.cache_path)
        end
      end

      def test_for_workflow_creates_cache_with_namespaced_directory
        with_fake_dot_roast_dir do |dot_roast_dir|
          workflow_name = "test_workflow"
          workflow_path = "/path/to/workflow.yml"

          cache = Roast::DotRoast::Cache.for_workflow(workflow_name, workflow_path)

          # The namespace should be workflow_name + first 4 chars of MD5 hash
          expected_namespace = workflow_name + Digest::MD5.hexdigest(workflow_path).first(4)
          expected_path = File.join(dot_roast_dir, "cache", expected_namespace)

          assert_instance_of(ActiveSupport::Cache::FileStore, cache)
          assert_equal(expected_path, cache.cache_path)
        end
      end

      def test_path_for_namespace_returns_correct_path
        with_fake_dot_roast_dir do |dot_roast_dir|
          namespace = "test_namespace"
          expected_path = File.join(dot_roast_dir, "cache", namespace)
          assert_equal(expected_path, Roast::DotRoast::Cache.path_for_namespace(namespace))
        end
      end

      def test_path_for_namespace_returns_base_path_for_empty_namespace
        with_fake_dot_roast_dir do |dot_roast_dir|
          expected_path = File.join(dot_roast_dir, "cache")
          assert_equal(expected_path, Roast::DotRoast::Cache.path_for_namespace(""))
        end
      end

      private

      def with_fake_dot_roast_dir
        Dir.mktmpdir do |dir|
          dot_roast_dir = File.join(dir, ".roast")
          Roast::DotRoast.stub(:root, dot_roast_dir) do
            yield dot_roast_dir
          end
        end
      end
    end
  end
end
