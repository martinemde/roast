# frozen_string_literal: true

require "digest"
require "roast/dot_roast"

module Roast
  module Helpers
    module FunctionCache
      autoload :Interceptor, "roast/helpers/function_cache/interceptor"

      class << self
        def for_workflow(workflow_name, workflow_path)
          for_namespace(namespace_from_workflow(workflow_name, workflow_path))
        end

        def for_namespace(namespace)
          cache_dir = Roast::DotRoast.ensure_subdir("cache")
          cache_path = namespace.empty? ? cache_dir : File.join(cache_dir, namespace)
          ActiveSupport::Cache::FileStore.new(cache_path)
        end

        def namespace_from_workflow(workflow_name, workflow_path)
          sanitized_name = workflow_name.parameterize.underscore
          workflow_path_sha = Digest::MD5.hexdigest(workflow_path).first(4)
          "#{sanitized_name}_#{workflow_path_sha}"
        end
      end
    end
  end
end
