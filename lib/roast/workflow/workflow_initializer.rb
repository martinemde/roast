# frozen_string_literal: true

require "raix"
require "roast/initializers"
require "roast/helpers/function_caching_interceptor"
require "roast/helpers/logger"
require "roast/workflow/base_workflow"

module Roast
  module Workflow
    # Handles initialization of workflow dependencies: initializers, tools, and API clients
    class WorkflowInitializer
      def initialize(configuration)
        @configuration = configuration
      end

      def setup
        load_roast_initializers
        include_tools
        configure_api_client
      end

      private

      def load_roast_initializers
        Roast::Initializers.load_all
      end

      def include_tools
        return unless @configuration.tools.present?

        BaseWorkflow.include(Raix::FunctionDispatch)
        BaseWorkflow.include(Roast::Helpers::FunctionCachingInterceptor) # Add caching support
        BaseWorkflow.include(*@configuration.tools.map(&:constantize))
      end

      def configure_api_client
        # assume that if the api_token is present, it's already configured by an initializer
        return if @configuration.api_token.present?

        begin
          case @configuration.api_provider
          when :openrouter
            configure_openrouter_client
          when :openai
            configure_openai_client
          else
            raise "Unsupported or missing api_provider in workflow configuration: #{@configuration.api_provider}"
          end
        rescue => e
          Roast::Helpers::Logger.error("Error configuring API client: #{e.message}")
          raise e
        end
      end

      def configure_openrouter_client
        raise "Missing api_token in workflow configuration" if @configuration.api_token.blank?

        $stderr.puts "Configuring OpenRouter client with token from workflow"
        require "open_router"

        Raix.configure do |config|
          config.openrouter_client = OpenRouter::Client.new(access_token: @configuration.api_token)
        end
      end

      def configure_openai_client
        raise "Missing api_token in workflow configuration" if @configuration.api_token.blank?

        $stderr.puts "Configuring OpenAI client with token from workflow"
        require "openai"

        Raix.configure do |config|
          config.openai_client = OpenAI::Client.new(access_token: @configuration.api_token)
        end
      end
    end
  end
end
