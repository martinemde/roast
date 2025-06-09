# frozen_string_literal: true

require "digest"
require "roast/helpers/logger"

module Roast
  module Helpers
    module FunctionCache
      class << self
        def for_workflow(workflow_name, workflow_path)
          namespace = workflow_name + Digest::MD5.hexdigest(workflow_path).first(4)
          for_namespace(namespace)
        end

        def for_namespace(namespace)
          ensure_exists
          ensure_gitignore_exists
          @cache = ActiveSupport::Cache::FileStore.new(path_for_namespace(namespace))
          @cache
        end

        def path_for_namespace(namespace)
          namespace.empty? ? path : File.join(path, namespace)
        end

        def path
          File.join(Roast.dot_roast_dir, "cache")
        end

        def ensure_exists
          FileUtils.mkdir_p(path) unless File.directory?(path)
        end

        def gitignore_path
          File.join(path, ".gitignore")
        end

        def ensure_gitignore_exists
          File.write(gitignore_path, "*") unless File.exist?(gitignore_path)
        end
      end

      # Intercepts function dispatching to add caching capabilities
      # This module wraps around Raix::FunctionDispatch to provide caching for tool functions
      module Interceptor
        def dispatch_tool_function(function_name, params)
          start_time = Time.now

          ActiveSupport::Notifications.instrument("roast.tool.execute", {
            function_name: function_name,
            params: params,
          })

          # Handle workflows with or without configuration
          result = if !respond_to?(:configuration) || configuration.nil?
            super(function_name, params)
          else
            function_config = if configuration.respond_to?(:function_config)
              configuration.function_config(function_name)
            else
              {}
            end

            # Check if caching is enabled - handle both formats:
            # 1. cache: true (boolean format)
            # 2. cache: { enabled: true } (hash format)
            cache_enabled = if function_config.is_a?(Hash)
              cache_config = function_config["cache"]
              if cache_config.is_a?(Hash)
                cache_config["enabled"]
              else
                # Direct boolean value
                cache_config
              end
            else
              false
            end

            if cache_enabled
              # Call the original function and pass in the cache
              cache = Roast::Helpers::FunctionCache.for_workflow(configuration.name, configuration.workflow_path)
              super(function_name, params, cache:)
            else
              Roast::Helpers::Logger.debug("⚠️ Caching not enabled for #{function_name}")
              super(function_name, params)
            end
          end

          execution_time = Time.now - start_time

          # Determine if caching was enabled for metrics
          cache_enabled = if defined?(function_config) && function_config.is_a?(Hash)
            cache_config = function_config["cache"]
            if cache_config.is_a?(Hash)
              cache_config["enabled"]
            else
              # Direct boolean value
              cache_config
            end
          else
            false
          end

          ActiveSupport::Notifications.instrument("roast.tool.complete", {
            function_name: function_name,
            execution_time: execution_time,
            cache_enabled: cache_enabled,
          })

          result
        rescue => e
          execution_time = Time.now - start_time

          ActiveSupport::Notifications.instrument("roast.tool.error", {
            function_name: function_name,
            error: e.class.name,
            message: e.message,
            execution_time: execution_time,
          })
          raise
        end
      end
    end
  end
end
