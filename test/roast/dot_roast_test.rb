# frozen_string_literal: true

require "test_helper"

module Roast
  class DotRoastTest < ActiveSupport::TestCase
    def ending_path
      File.join(Roast::ROOT, "test", "fixtures", "config_root")
    end

    def test_root_with_no_roast_folder
      starting_path = File.join(ending_path, "empty")
      path = Roast::DotRoast.root(starting_path, ending_path)
      expected_path = File.join(starting_path, ".roast")
      assert_equal(expected_path, path)
    end

    def test_root_with_shallow_roast_folder
      starting_path = File.join(ending_path, "shallow")
      path = Roast::DotRoast.root(starting_path, ending_path)
      expected_path = File.join(starting_path, ".roast")
      assert_equal(expected_path, path)
    end

    def test_root_with_nested_roast_folder
      starting_path = File.join(ending_path, "deeply", "nested", "start", "folder")
      path = Roast::DotRoast.root(starting_path, ending_path)
      expected_path = File.join(ending_path, "deeply", ".roast")
      assert_equal(expected_path, path)
    end

    def test_root_starting_path_not_subdir_of_ending_path
      Dir.mktmpdir do |tmpdir|
        starting_path = tmpdir

        Roast::Helpers::Logger.expects(:warn).once

        path = Roast::DotRoast.root(starting_path, ending_path)
        expected_path = File.join(starting_path, ".roast")
        assert_equal(expected_path, path)
      end
    end

    def test_ensure_subdir_creates_directory_with_gitignore
      Dir.mktmpdir do |tmpdir|
        Roast::DotRoast.stubs(:root).returns(tmpdir)

        result_path = Roast::DotRoast.ensure_subdir("test_subdir")
        expected_path = File.join(tmpdir, "test_subdir")

        assert_equal(expected_path, result_path)
        assert(File.directory?(result_path))
        assert(File.exist?(File.join(result_path, ".gitignore")))
        assert_equal("*", File.read(File.join(result_path, ".gitignore")))
      end
    end

    def test_ensure_subdir_creates_directory_without_gitignore
      Dir.mktmpdir do |tmpdir|
        Roast::DotRoast.stubs(:root).returns(tmpdir)

        result_path = Roast::DotRoast.ensure_subdir("test_subdir", gitignored: false)
        expected_path = File.join(tmpdir, "test_subdir")

        assert_equal(expected_path, result_path)
        assert(File.directory?(result_path))
        assert_not(File.exist?(File.join(result_path, ".gitignore")))
      end
    end

    def test_ensure_subdir_does_not_overwrite_existing_gitignore
      Dir.mktmpdir do |tmpdir|
        Roast::DotRoast.stubs(:root).returns(tmpdir)

        subdir_path = File.join(tmpdir, "test_subdir")
        FileUtils.mkdir_p(subdir_path)
        custom_content = "custom content"
        File.write(File.join(subdir_path, ".gitignore"), custom_content)

        result_path = Roast::DotRoast.ensure_subdir("test_subdir")

        assert_equal(custom_content, File.read(File.join(result_path, ".gitignore")))
      end
    end

    def test_subdir_path_returns_existing_directory
      Dir.mktmpdir do |tmpdir|
        Roast::DotRoast.stubs(:root).returns(tmpdir)

        subdir_path = File.join(tmpdir, "existing_subdir")
        FileUtils.mkdir_p(subdir_path)

        result = Roast::DotRoast.subdir_path("existing_subdir")
        assert_equal(subdir_path, result)
      end
    end

    def test_subdir_path_returns_nil_for_nonexistent_directory
      Dir.mktmpdir do |tmpdir|
        Roast::DotRoast.stubs(:root).returns(tmpdir)

        result = Roast::DotRoast.subdir_path("nonexistent_subdir")
        assert_nil(result)
      end
    end
  end
end
