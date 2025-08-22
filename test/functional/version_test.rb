# frozen_string_literal: true

require "test_helper"

class VersionTest < FunctionalTest
  test "outputs the current version number" do
    result = roast(["version"])

    assert_match Regexp.new("Roast version #{Roast::VERSION}"), result.output
  end
end
