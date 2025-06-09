# frozen_string_literal: true

require "test_helper"

module Roast
  class DotRoast
    class InitializersTest < ActiveSupport::TestCase
      def test_with_invalid_initializers_folder
        with_fake_initializers_dir("invalid") do |_|
          out, err = capture_io do
            Roast::DotRoast::Initializers.load_all
          end

          assert_equal("", out)
          assert_equal("", err)
        end
      end

      def test_with_no_initializer_files
        with_fake_initializers_dir("empty") do |initializers_dir|
          out, err = capture_io do
            Roast::DotRoast::Initializers.load_all
          end

          assert_equal("", out)
          expected_output = <<~OUTPUT
            Loading project initializers from #{initializers_dir}
          OUTPUT
          assert_equal(expected_output, err)
        end
      end

      def test_with_initializer_file_that_raises
        with_fake_initializers_dir("raises") do |initializers_dir|
          out, err = capture_io do
            Roast::DotRoast::Initializers.load_all
          end

          expected_output = <<~OUTPUT
            ERROR: Error loading initializers: exception class/object expected
          OUTPUT
          assert_includes(out, expected_output)
          expected_stderr = <<~OUTPUT
            Loading project initializers from #{initializers_dir}
            Loading initializer: #{File.join(initializers_dir, "hell.rb")}
          OUTPUT
          assert_equal(expected_stderr, err)
        end
      end

      def test_with_an_initializer_file
        with_fake_initializers_dir("single") do |initializers_dir|
          out, err = capture_io do
            Roast::DotRoast::Initializers.load_all
          end

          assert_equal("", out)
          expected_output = <<~OUTPUT
            Loading project initializers from #{initializers_dir}
            Loading initializer: #{File.join(initializers_dir, "noop.rb")}
          OUTPUT
          assert_equal(expected_output, err)
        end
      end

      def test_with_multiple_initializer_files
        with_fake_initializers_dir("multiple") do |initializers_dir|
          out, err = capture_io do
            Roast::DotRoast::Initializers.load_all
          end

          assert_equal("", out)
          expected_output = <<~OUTPUT
            Loading project initializers from #{initializers_dir}
            Loading initializer: #{File.join(initializers_dir, "first.rb")}
            Loading initializer: #{File.join(initializers_dir, "second.rb")}
            Loading initializer: #{File.join(initializers_dir, "third.rb")}
          OUTPUT
          assert_equal(expected_output, err)
        end
      end

      private

      def with_fake_initializers_dir(fixture_name)
        fixture_path = path_for_initializers(fixture_name)
        Roast::DotRoast::Initializers.stub(:path, fixture_path) do
          yield fixture_path
        end
      end

      def path_for_initializers(name)
        File.join(Roast::ROOT, "test", "fixtures", "initializers", name)
      end
    end
  end
end
