# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    module Validators
      # Base class for all validators
      class BaseValidator
        attr_reader :errors, :warnings

        def initialize(parsed_yaml, workflow_path = nil)
          @parsed_yaml = parsed_yaml
          @workflow_path = workflow_path
          @errors = []
          @warnings = []
        end

        def validate
          raise NotImplementedError, "Subclasses must implement validate"
        end

        def valid?
          validate
          @errors.empty?
        end

        protected

        def add_error(type:, message:, suggestion: nil, **metadata)
          error = { type: type, message: message }
          error[:suggestion] = suggestion if suggestion
          error.merge!(metadata)
          @errors << error
        end

        def add_warning(type:, message:, suggestion: nil, **metadata)
          warning = { type: type, message: message }
          warning[:suggestion] = suggestion if suggestion
          warning.merge!(metadata)
          @warnings << warning
        end
      end
    end
  end
end
