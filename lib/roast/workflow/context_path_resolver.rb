# typed: false
# frozen_string_literal: true

module Roast
  module Workflow
    # Determines the context path for workflow and step classes
    class ContextPathResolver
      class << self
        # Determine the directory where the actual class is defined
        # @param klass [Class] The class to find the context path for
        # @return [String] The directory path containing the class definition
        def resolve(klass)
          # Try to get the file path where the class is defined
          path = if klass.name&.include?("::")
            # For namespaced classes like Roast::Workflow::Grading::Workflow
            # Convert the class name to a relative path
            class_path = klass.name.underscore + ".rb"
            # Look through load path to find the actual file
            $LOAD_PATH.map { |p| File.join(p, class_path) }.find { |f| File.exist?(f) }
          end

          # Fall back to trying to get the source location
          if path.nil? && klass.instance_methods(false).any?
            # Try to get source location from any instance method
            method = klass.instance_methods(false).first
            source_location = klass.instance_method(method).source_location
            path = source_location&.first
          end

          # Return directory containing the class definition
          # or the current directory if we can't find it
          File.dirname(path || Dir.pwd)
        end

        # Resolve context path for an instance
        # @param instance [Object] The instance to find the context path for
        # @return [String] The directory path containing the class definition
        def resolve_for_instance(instance)
          resolve(instance.class)
        end
      end
    end
  end
end
