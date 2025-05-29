# Smart Coercion Defaults

This example demonstrates how Roast applies intelligent defaults for boolean coercion based on the type of expression being evaluated.

## Default Coercion Rules

When a step is used in a boolean context (like `if`, `unless`, or `until` conditions) and no explicit `coerce_to` is specified, Roast applies these smart defaults:

1. **Ruby Expressions** (`{{expression}}`) → Regular boolean coercion (`!!value`)
   - `nil` and `false` are falsy
   - Everything else is truthy (including 0, empty arrays, etc.)

2. **Bash Commands** (`$(command)`) → Exit code interpretation
   - Exit code 0 = true (success)
   - Non-zero exit code = false (failure)

3. **Prompt/Step Names** → LLM boolean interpretation
   - Analyzes natural language responses for yes/no intent
   - "Yes", "True", "Affirmative" → true
   - "No", "False", "Negative" → false

4. **Non-string Values** → Regular boolean coercion

## Examples

### Ruby Expression (Regular Boolean)
```yaml
- repeat:
    until: "{{counter >= 5}}"  # Uses !! coercion
    steps:
      - increment: counter
```

### Bash Command (Exit Code)
```yaml
- repeat:
    until: "$(test -f /tmp/done)"  # True when file exists (exit 0)
    steps:
      - wait: 1
```

### Prompt Response (LLM Boolean)
```yaml
- if: "Should we continue?"  # Interprets "Yes, let's continue" as true
  then:
    - proceed: "Continuing..."
```

## Overriding Defaults

You can always override the default coercion by specifying `coerce_to` directly in the step:

```yaml
- each: "get_items"
  as: "item"
  coerce_to: iterable  # Override default to split into array
  steps:
    - process: "{{item}}"
```

## Supported Coercion Types

- `boolean` - Standard Ruby truthiness (!! operator)
- `llm_boolean` - Natural language yes/no interpretation
- `iterable` - Convert to array (splits strings on newlines)