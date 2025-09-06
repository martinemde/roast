# Raix Interface Contract Test

This directory contains an RSpec test file that captures the implicit interface contract between the Roast project and the Raix gem. The purpose of this test is to ensure that Raix maintains compatibility with Roast's usage patterns across versions.

## Purpose

The Roast project depends heavily on Raix for AI chat completions and tool dispatch functionality. This test file documents and validates all the ways that Roast integrates with Raix, including:

- Core modules (`Raix::ChatCompletion`, `Raix::FunctionDispatch`, `Raix::MCP`)
- Configuration system and client management
- Tool dispatch and caching interfaces
- MCP (Model Context Protocol) integration
- Error handling patterns
- Thread-local storage patterns

## Usage

### Running in the Roast Project

From the Roast project root:

```bash
# Install RSpec if not already installed
bundle install

# Run the contract tests
bundle exec rspec spec/raix_interface_contract_spec.rb
```

### Running in the Raix Project

The primary use case for this test is to copy it to the Raix project and run it there to ensure compatibility:

1. Copy `spec/raix_interface_contract_spec.rb` to the Raix project
2. Copy `spec/spec_helper.rb` to the Raix project (or integrate with existing spec_helper)
3. Copy `.rspec` configuration if needed
4. Run the tests in the Raix project:

```bash
bundle exec rspec raix_interface_contract_spec.rb
```

## What the Tests Cover

### Core Modules
- **Raix::ChatCompletion**: Validates `chat_completion` method, `transcript` management, and `prompt` functionality
- **Raix::FunctionDispatch**: Validates `dispatch_tool_function` method and caching interface
- **Raix::MCP**: Validates MCP integration patterns and `StdioClient` class

### Configuration System
- **Raix.configure**: Block-based configuration setup
- **Client Management**: OpenAI and OpenRouter client configuration and validation
- **Token Management**: Access token handling and whitespace stripping

### Integration Patterns
- **BaseWorkflow Pattern**: How Roast's main workflow class uses Raix
- **ContextSummarizer Pattern**: Independent usage for context summarization
- **FunctionCachingInterceptor Pattern**: Method override for adding caching

### Error Handling
- **Faraday Errors**: ResourceNotFound and UnauthorizedError compatibility
- **Thread Storage**: Response tracking for instrumentation

## Interface Requirements

This test validates that Raix provides:

1. **Module Inclusion**: All modules can be included in classes
2. **Method Signatures**: All expected methods exist with correct parameter handling
3. **State Management**: Transcript and model state can be managed independently
4. **Configuration**: Block-based configuration with proper client management
5. **Extensibility**: Methods can be overridden for custom behavior (caching, instrumentation)

## Maintenance

When Roast's usage of Raix changes, this test should be updated to reflect the new interface requirements. Similarly, if Raix changes its interface, this test will help identify breaking changes that affect Roast.

## Integration with CI

This test can be integrated into Raix's CI pipeline to catch compatibility issues early:

```yaml
# Example GitHub Actions step
- name: Test Roast compatibility
  run: bundle exec rspec raix_interface_contract_spec.rb
```

By maintaining this contract test, both projects can evolve while ensuring compatibility is preserved.