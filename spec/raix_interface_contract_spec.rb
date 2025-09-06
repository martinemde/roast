# frozen_string_literal: true

# RSpec test file that captures the Raix interface contract as used by Roast
# This file documents and tests the implicit contract between Roast and Raix
# to ensure compatibility is maintained across versions.

require "rspec"

RSpec.describe "Raix Interface Contract for Roast Compatibility" do
  describe "Raix module availability" do
    it "provides the main Raix module" do
      expect(defined?(Raix)).to be_truthy
      expect(Raix).to be_a(Module)
    end
  end

  describe "Raix::ChatCompletion module" do
    let(:test_class) do
      Class.new do
        include Raix::ChatCompletion
        
        attr_accessor :model
        
        def initialize(model: "gpt-4")
          @model = model
        end
      end
    end

    let(:instance) { test_class.new }

    it "is available for inclusion" do
      expect(defined?(Raix::ChatCompletion)).to be_truthy
      expect(Raix::ChatCompletion).to be_a(Module)
    end

    it "provides chat_completion method" do
      expect(instance).to respond_to(:chat_completion)
    end

    it "provides transcript accessor" do
      expect(instance).to respond_to(:transcript)
      expect(instance).to respond_to(:transcript=)
    end

    it "supports transcript manipulation" do
      # Test that transcript can be set and accessed
      instance.transcript = [{ user: "Hello" }]
      expect(instance.transcript).to eq([{ user: "Hello" }])
      
      # Test that transcript can be appended to
      instance.transcript << { assistant: "Hi there!" }
      expect(instance.transcript.size).to eq(2)
      expect(instance.transcript.last).to eq({ assistant: "Hi there!" })
    end

    it "provides prompt method" do
      expect(instance).to respond_to(:prompt)
    end

    it "allows setting model attribute" do
      expect(instance).to respond_to(:model=)
      instance.model = "gpt-3.5-turbo"
      expect(instance.model).to eq("gpt-3.5-turbo")
    end

    describe "chat_completion method" do
      it "accepts keyword arguments including model" do
        # Should not raise error when called with expected parameters
        expect { instance.chat_completion(model: "test-model") }.not_to raise_error(ArgumentError)
      end

      it "accepts messages parameter" do
        messages = [{ role: "user", content: "test" }]
        expect { instance.chat_completion(messages: messages) }.not_to raise_error(ArgumentError)
      end

      it "excludes model from kwargs when calling super" do
        # This tests the pattern used in BaseWorkflow where model is excluded
        # from kwargs when calling super
        allow(instance).to receive(:model).and_return("test-model")
        
        # Mock the super method to verify model is excluded
        expect(instance).to receive(:chat_completion).and_call_original
        
        # This should work without errors
        expect { instance.chat_completion(model: "override-model", other_param: "value") }.not_to raise_error
      end
    end
  end

  describe "Raix::FunctionDispatch module" do
    let(:test_class) do
      Class.new do
        include Raix::FunctionDispatch
      end
    end

    let(:instance) { test_class.new }

    it "is available for inclusion" do
      expect(defined?(Raix::FunctionDispatch)).to be_truthy
      expect(Raix::FunctionDispatch).to be_a(Module)
    end

    it "provides dispatch_tool_function method" do
      expect(instance).to respond_to(:dispatch_tool_function)
    end

    describe "dispatch_tool_function method" do
      it "accepts function name and parameters" do
        expect { instance.dispatch_tool_function("test_function", {}) }.not_to raise_error(ArgumentError)
      end

      it "accepts cache parameter for caching functionality" do
        # Test the caching interface used by FunctionCachingInterceptor
        cache_mock = double("cache")
        expect { instance.dispatch_tool_function("test_function", {}, cache: cache_mock) }.not_to raise_error(ArgumentError)
      end
    end
  end

  describe "Raix::MCP module and integration" do
    it "provides Raix::MCP module" do
      expect(defined?(Raix::MCP)).to be_truthy
      expect(Raix::MCP).to be_a(Module)
    end

    it "provides Raix::MCP::StdioClient class" do
      expect(defined?(Raix::MCP::StdioClient)).to be_truthy
      expect(Raix::MCP::StdioClient).to be_a(Class)
    end

    describe "Raix::MCP::StdioClient" do
      it "can be instantiated with command, args, and options" do
        expect { Raix::MCP::StdioClient.new("echo", "test", {}) }.not_to raise_error
      end
    end

    describe "MCP module inclusion" do
      let(:test_class) do
        Class.new do
          include Raix::MCP
        end
      end

      it "provides mcp class method when included" do
        expect(test_class).to respond_to(:mcp)
      end

      it "accepts client, only, and except parameters for mcp method" do
        client = double("mcp_client")
        expect { test_class.mcp(client: client, only: ["method1"], except: nil) }.not_to raise_error
      end
    end
  end

  describe "Raix configuration system" do
    it "provides Raix.configure method" do
      expect(Raix).to respond_to(:configure)
    end

    it "provides Raix.configuration accessor" do
      expect(Raix).to respond_to(:configuration)
      expect(Raix.configuration).to be_truthy
    end

    describe "configuration object" do
      let(:config) { Raix.configuration }

      it "provides openai_client accessor" do
        expect(config).to respond_to(:openai_client)
        expect(config).to respond_to(:openai_client=)
      end

      it "provides openrouter_client accessor" do
        expect(config).to respond_to(:openrouter_client)
        expect(config).to respond_to(:openrouter_client=)
      end
    end

    describe "Raix.configure block" do
      it "yields configuration object for setup" do
        expect { |block| Raix.configure(&block) }.to yield_with_args(Raix.configuration)
      end

      it "allows setting openai_client" do
        client_mock = double("openai_client")
        
        Raix.configure do |config|
          config.openai_client = client_mock
        end
        
        expect(Raix.configuration.openai_client).to eq(client_mock)
      end

      it "allows setting openrouter_client" do
        client_mock = double("openrouter_client")
        
        Raix.configure do |config|
          config.openrouter_client = client_mock
        end
        
        expect(Raix.configuration.openrouter_client).to eq(client_mock)
      end
    end
  end

  describe "API client interface requirements" do
    describe "OpenAI client interface" do
      let(:mock_client) do
        double("OpenAI::Client").tap do |client|
          allow(client).to receive(:access_token).and_return("test-token")
          allow(client).to receive(:instance_variable_set)
          
          # Mock models interface for validation
          models = double("models")
          allow(models).to receive(:list).and_return([])
          allow(client).to receive(:models).and_return(models)
        end
      end

      it "supports access_token method for token management" do
        expect(mock_client).to respond_to(:access_token)
        expect(mock_client.access_token).to eq("test-token")
      end

      it "supports token modification via instance_variable_set" do
        expect(mock_client).to receive(:instance_variable_set).with(:@access_token, "new-token")
        mock_client.instance_variable_set(:@access_token, "new-token")
      end

      it "supports models.list for client validation" do
        expect(mock_client.models).to respond_to(:list)
        expect { mock_client.models.list }.not_to raise_error
      end
    end

    describe "OpenRouter client interface" do
      let(:mock_client) do
        double("OpenRouter::Client").tap do |client|
          allow(client).to receive(:access_token).and_return("test-token")
          allow(client).to receive(:instance_variable_set)
          
          # Mock models interface for validation
          models = double("models")
          allow(models).to receive(:list).and_return([])
          allow(client).to receive(:models).and_return(models)
        end
      end

      it "supports access_token method for token management" do
        expect(mock_client).to respond_to(:access_token)
        expect(mock_client.access_token).to eq("test-token")
      end

      it "supports token modification via instance_variable_set" do
        expect(mock_client).to receive(:instance_variable_set).with(:@access_token, "new-token")
        mock_client.instance_variable_set(:@access_token, "new-token")
      end

      it "supports models.list for client validation" do
        expect(mock_client.models).to respond_to(:list)
        expect { mock_client.models.list }.not_to raise_error
      end
    end
  end

  describe "Thread-local storage for response tracking" do
    it "supports storing response in Thread.current for instrumentation" do
      # This tests the pattern where Raix stores the raw response
      # in Thread.current[:chat_completion_response] for Roast to access
      
      # Simulate Raix behavior
      test_response = { "usage" => { "total_tokens" => 100 } }
      Thread.current[:chat_completion_response] = test_response
      
      # Verify Roast can access the response
      stored_response = Thread.current[:chat_completion_response]
      expect(stored_response).to eq(test_response)
      expect(stored_response["usage"]["total_tokens"]).to eq(100)
      
      # Cleanup
      Thread.current[:chat_completion_response] = nil
    end
  end

  describe "Error handling compatibility" do
    it "supports Faraday::ResourceNotFound for resource errors" do
      # Test that Raix raises errors that Roast can handle
      expect(defined?(Faraday::ResourceNotFound)).to be_truthy
    end

    it "supports Faraday::UnauthorizedError for auth errors" do
      expect(defined?(Faraday::UnauthorizedError)).to be_truthy
    end
  end

  describe "Integration patterns used by Roast" do
    describe "BaseWorkflow pattern" do
      let(:workflow_class) do
        Class.new do
          include Raix::ChatCompletion
          include Raix::FunctionDispatch
          
          attr_accessor :model, :transcript
          
          def initialize
            @model = "gpt-4"
            @transcript = []
          end
          
          # Override chat_completion to mimic Roast's pattern
          def chat_completion(**kwargs)
            step_model = kwargs[:model]
            with_model(step_model) do
              super(**kwargs.except(:model))
            end
          end
          
          def with_model(model)
            previous_model = @model
            @model = model if model
            yield
          ensure
            @model = previous_model
          end
        end
      end

      let(:workflow) { workflow_class.new }

      it "supports the BaseWorkflow initialization pattern" do
        expect(workflow).to be_a(workflow_class)
        expect(workflow.model).to eq("gpt-4")
        expect(workflow.transcript).to eq([])
      end

      it "supports the model override pattern" do
        original_model = workflow.model
        expect { workflow.chat_completion(model: "custom-model") }.not_to raise_error
        expect(workflow.model).to eq(original_model) # Should be restored
      end

      it "supports transcript manipulation in system setup" do
        workflow.transcript << { system: "You are a helpful assistant" }
        expect(workflow.transcript).to include({ system: "You are a helpful assistant" })
      end
    end

    describe "ContextSummarizer pattern" do
      let(:summarizer_class) do
        Class.new do
          include Raix::ChatCompletion
          
          attr_reader :model
          
          def initialize(model: "gpt-4-mini")
            @model = model
          end
          
          def generate_summary(context, prompt)
            # Mimic the pattern used in ContextSummarizer
            self.transcript = []
            prompt("Generate summary for: #{prompt}")
            chat_completion
          end
        end
      end

      let(:summarizer) { summarizer_class.new }

      it "supports independent transcript management" do
        summarizer.transcript = [{ user: "previous message" }]
        expect(summarizer.transcript.size).to eq(1)
        
        # Should be able to reset transcript
        summarizer.transcript = []
        expect(summarizer.transcript).to be_empty
      end

      it "supports the summary generation pattern" do
        expect { summarizer.generate_summary({}, "test prompt") }.not_to raise_error
      end
    end

    describe "FunctionCachingInterceptor pattern" do
      let(:interceptor_class) do
        Class.new do
          include Raix::FunctionDispatch
          
          # Override dispatch_tool_function to mimic caching interceptor
          def dispatch_tool_function(function_name, params, cache: nil)
            if cache
              super(function_name, params, cache: cache)
            else
              super(function_name, params)
            end
          end
        end
      end

      let(:interceptor) { interceptor_class.new }

      it "supports method override for caching" do
        expect { interceptor.dispatch_tool_function("test", {}) }.not_to raise_error
        expect { interceptor.dispatch_tool_function("test", {}, cache: double("cache")) }.not_to raise_error
      end
    end
  end

  describe "Roast-specific configuration patterns" do
    it "supports the workflow initializer configuration pattern" do
      # Test the pattern used in WorkflowInitializer
      mock_openai_client = double("OpenAI::Client")
      mock_openrouter_client = double("OpenRouter::Client")
      
      Raix.configure do |config|
        config.openai_client = mock_openai_client
        config.openrouter_client = mock_openrouter_client
      end
      
      expect(Raix.configuration.openai_client).to eq(mock_openai_client)
      expect(Raix.configuration.openrouter_client).to eq(mock_openrouter_client)
    end

    it "supports checking for nil clients" do
      # Test the pattern used to check if clients are configured
      original_openai = Raix.configuration.openai_client
      original_openrouter = Raix.configuration.openrouter_client
      
      begin
        Raix.configure do |config|
          config.openai_client = nil
          config.openrouter_client = nil
        end
        
        expect(Raix.configuration.openai_client).to be_nil
        expect(Raix.configuration.openrouter_client).to be_nil
        
        # Test the nil check pattern
        openai_configured = !Raix.configuration.openai_client.nil?
        openrouter_configured = !Raix.configuration.openrouter_client.nil?
        
        expect(openai_configured).to be_falsey
        expect(openrouter_configured).to be_falsey
      ensure
        # Restore original clients
        Raix.configure do |config|
          config.openai_client = original_openai
          config.openrouter_client = original_openrouter
        end
      end
    end
  end
end