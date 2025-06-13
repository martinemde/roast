# frozen_string_literal: true

require "test_helper"

class RoastToolsApplyDiffTest < ActiveSupport::TestCase
  def setup
    @temp_dir = File.join(Dir.pwd, "test", "tmp", "apply_diff_test_dir_#{Time.now.to_i}")
    @test_file_path = File.join(@temp_dir, "test_file.txt")
    FileUtils.mkdir_p(@temp_dir)
    File.write(@test_file_path, "line 1\nline 2\nline 3\n")
  end

  def teardown
    FileUtils.remove_entry(@temp_dir) if File.exist?(@temp_dir)
  end

  test ".call returns error for non-existent file" do
    non_existent_file = File.join(@temp_dir, "non_existent.txt")
    result = Roast::Tools::ApplyDiff.call(non_existent_file, "old", "new")

    assert_equal "File not found: #{non_existent_file}", result
  end

  test ".call returns error when old content not found" do
    result = Roast::Tools::ApplyDiff.call(@test_file_path, "non-existent content", "new content")

    assert_equal "Old content not found in file: #{@test_file_path}", result
  end

  test ".call applies changes when user confirms" do
    # Mock CLI::UI::Prompt to simulate user saying "yes"
    CLI::UI::Prompt.stub(:ask, "yes") do
      result = Roast::Tools::ApplyDiff.call(@test_file_path, "line 2", "modified line 2")

      assert_equal "✅ Changes applied to #{@test_file_path}", result
      assert_equal "line 1\nmodified line 2\nline 3\n", File.read(@test_file_path)
    end
  end

  test ".call cancels changes when user declines" do
    original_content = File.read(@test_file_path)

    # Mock CLI::UI::Prompt to simulate user saying "no"
    CLI::UI::Prompt.stub(:ask, "no") do
      result = Roast::Tools::ApplyDiff.call(@test_file_path, "line 2", "modified line 2")

      assert_equal "❌ Changes cancelled for #{@test_file_path}", result
      assert_equal original_content, File.read(@test_file_path)
    end
  end

  test ".call handles description parameter" do
    CLI::UI::Prompt.stub(:ask, "yes") do
      result = Roast::Tools::ApplyDiff.call(@test_file_path, "line 2", "modified line 2", "Test description")

      assert_equal "✅ Changes applied to #{@test_file_path}", result
    end
  end

  test ".call handles exceptions gracefully" do
    # Make the file unwritable to simulate an error
    FileUtils.chmod(0o000, @test_file_path)

    CLI::UI::Prompt.stub(:ask, "yes") do
      result = Roast::Tools::ApplyDiff.call(@test_file_path, "line 2", "modified line 2")

      assert_match(/Error applying diff:/, result)
    end
  ensure
    FileUtils.chmod(0o644, @test_file_path)
  end

  class DummyBaseClass
    class << self
      attr_reader :function_called, :function_name, :function_description, :function_params, :function_block

      def function(name, description, **params, &block)
        @function_called = true
        @function_name = name
        @function_description = description
        @function_params = params
        @function_block = block
      end
    end
  end

  test ".call shows colored diff output" do
    # Test that CLI::UI.fmt formatting works correctly
    CLI::UI.enable_color = true
    assert_equal "\e[0;31mtest\e[0m", CLI::UI.fmt("{{red:test}}")
    assert_equal "\e[0;32mtest\e[0m", CLI::UI.fmt("{{green:test}}")
    assert_equal "\e[0;36mtest\e[0m", CLI::UI.fmt("{{cyan:test}}")
    assert_equal "\e[0;1mtest\e[0m", CLI::UI.fmt("{{bold:test}}")
  end

  test ".included adds function to the base class" do
    Roast::Tools::ApplyDiff.included(DummyBaseClass)
    assert DummyBaseClass.function_called, "Function should be called on inclusion"
    assert_equal :apply_diff, DummyBaseClass.function_name
    assert_equal "Show a diff to the user and apply changes based on their yes/no response", DummyBaseClass.function_description
  end
end
