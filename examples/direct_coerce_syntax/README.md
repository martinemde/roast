# Direct Coerce Syntax

This example demonstrates the simplified syntax for specifying `coerce_to` and other configuration options directly on iteration steps, without needing a `config` block.

## Direct Syntax

Instead of:
```yaml
- repeat:
    until: "condition"
    config:
      coerce_to: boolean
```

You can now write:
```yaml
- repeat:
    until: "condition"
    coerce_to: boolean
```

## Benefits

1. **Cleaner YAML** - Less nesting, easier to read
2. **More intuitive** - Configuration options are at the same level as other step properties
3. **Backward compatible** - Old `config` block syntax still works

## Supported Options

All step configuration options can be specified directly:
- `coerce_to` - Type coercion (boolean, llm_boolean, iterable)
- `print_response` - Whether to print LLM responses
- `loop` - Auto-loop behavior
- `json` - JSON response mode
- `params` - Additional parameters
- `model` - Model override

## Precedence

If both syntaxes are present, direct properties take precedence:
```yaml
- repeat:
    until: "condition"
    coerce_to: llm_boolean  # This wins
    config:
      coerce_to: boolean    # This is ignored
```