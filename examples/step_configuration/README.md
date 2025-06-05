# Step Configuration Example

This example demonstrates how to configure various step types in Roast workflows, including:
- Inline prompts
- Iterator steps (each/repeat)
- Regular steps

## Configuration Options

All step types support the following configuration options:

- `model`: The AI model to use (e.g., "gpt-4o", "claude-3-opus")
- `print_response`: Whether to print the response to stdout (true/false)
- `json`: Whether to expect a JSON response (true/false)
- `params`: Additional parameters to pass to the model (e.g., temperature, max_tokens)
- `coerce_to`: How to convert the step result (options: "boolean", "llm_boolean", "iterable")

## Configuration Precedence

1. **Step-specific configuration** takes highest precedence
2. **Global configuration** (defined at the workflow level) applies to all steps without specific configuration
3. **Default values** are used when no configuration is provided

## Inline Prompt Configuration

Inline prompts can be configured in two ways:

### As a top-level key:
```yaml
analyze the code:
  model: gpt-4o
  print_response: true
```

### Inline in the steps array:
```yaml
steps:
  - suggest improvements:
      model: claude-3-opus
      params:
        temperature: 0.9
```

## Iterator Configuration

Both `each` and `repeat` steps support configuration:

```yaml
each:
  each: "{{files}}"
  as: file
  model: gpt-3.5-turbo
  steps:
    - process {{file}}

repeat:
  repeat: true
  until: "{{done}}"
  model: gpt-4o
  print_response: true
  steps:
    - check status
```

## Coercion Types

The `coerce_to` option allows you to convert step results to specific types:

- **`boolean`**: Converts any value to true/false (nil, false, empty string → false; everything else → true)
- **`llm_boolean`**: Interprets natural language responses as boolean (e.g., "Yes", "Definitely!" → true; "No", "Not yet" → false)
- **`iterable`**: Ensures the result can be iterated over (splits strings by newlines if needed)

This is particularly useful when:
- Using steps in conditional contexts (if/unless)
- Using steps as conditions in repeat loops
- Processing step results in each loops

## Running the Example

```bash
bin/roast examples/step_configuration/workflow.yml
```

Note: This example is for demonstration purposes and shows the configuration syntax. You'll need to adapt it to your specific use case with appropriate prompts and logic.