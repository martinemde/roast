# frozen_string_literal: true

module Roast
  module Errors
    # Custom error for API resource not found (404) responses
    class ResourceNotFoundError < StandardError; end

    # Custom error for when API authentication fails
    class AuthenticationError < StandardError; end

    # Exit the app, for instance via Ctrl-C during an InputStep
    class ExitEarly < StandardError; end
  end
end
