# frozen_string_literal: true

require "test_helper"

class VersionTest < FunctionalTest
  test "outputs the current version number" do
    assert_output Regexp.new("Roast version #{Roast::VERSION}") do
      roast("version")
    end
  end
end
