# Direct Coerce Syntax

This example demonstrates the simplified syntax for specifying `coerce_to` and other configuration options directly on iteration steps.

## Direct Syntax

Configuration options are specified directly on the step:

```yaml
- repeat:
    until: "condition"
    coerce_to: boolean
    print_response: true
    model: "claude-3-haiku"
    steps: [...]
```

## Benefits

1. **Cleaner YAML** - No unnecessary nesting
2. **More intuitive** - Configuration options are at the same level as other step properties
3. **Consistent** - Matches how other step properties are specified

## Supported Options

All step configuration options can be specified directly:
- `coerce_to` - Type coercion (boolean, llm_boolean, iterable)
- `print_response` - Whether to print LLM responses
- `loop` - Auto-loop behavior
- `json` - JSON response mode
- `params` - Additional parameters
- `model` - Model override