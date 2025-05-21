# Using Iteration with Standardized Syntax

## Overview

Roast supports powerful iteration constructs with the `repeat` and `each` workflow steps. These features now support a standardized approach to evaluating expressions using the double-curly braces syntax (`{{...}}`).

## Syntax Options for Iteration Inputs

Both `until` conditions (in `repeat`) and collection expressions (in `each`) accept the following formats:

### 1. Ruby Expressions with `{{...}}` Syntax

For evaluating Ruby code in the workflow context:

```yaml
# Repeat until a condition is met
- repeat:
    steps:
      - process_item
    until: "{{output['counter'] >= 5}}"
    max_iterations: 10

# Iterate over a collection
- each: "{{output['items'].filter { |item| item.active? }}}"
  as: "current_item"
  steps:
    - process_item
```

### 2. Bash Commands with `$(...)` Syntax

For executing shell commands and using their results:

```yaml
# Repeat until a command succeeds
- repeat:
    steps:
      - check_service
    until: "$(curl -s -o /dev/null -w '%{http_code}' http://service.local/ | grep -q 200)"
    max_iterations: 20

# Iterate over files returned by a command
- each: "$(find . -name '*.rb' -type f)"
  as: "current_file"
  steps:
    - process_file
```

### 3. Step Names (as strings)

For using the result of another step:

```yaml
# Repeat until a step returns a truthy value
- repeat:
    steps:
      - process_batch
    until: "check_completion"
    max_iterations: 100

# Iterate over items returned by a step
- each: "get_pending_items"
  as: "pending_item"
  steps:
    - process_pending_item
```

### 4. Prompt Content

For defining prompts directly in the workflow:

```yaml
# Using a prompt to determine continuation
- repeat:
    steps:
      - process_content
    until:
      prompt: prompts/check_completion.md
      model: claude-3-haiku
    max_iterations: 10

# Using a prompt to generate a collection
- each:
    prompt: prompts/generate_test_cases.md
    model: claude-3-haiku
  as: "test_case"
  steps:
    - run_test
```

## Type Coercion

Values are automatically coerced to the appropriate types:

- For `until` conditions: Values are coerced to booleans (using Ruby's truthiness rules)
- For `each` collections: Values are coerced to iterables (converted to arrays of lines if needed)

## Migrating Existing Workflows

If you're updating existing workflows:

1. For Ruby expressions, wrap them in `{{...}}`:
   ```yaml
   # Old
   until: "output['counter'] >= 5"
   
   # New
   until: "{{output['counter'] >= 5}}"
   ```

2. Bash commands, step names, and prompts can remain unchanged.

## Best Practices

- Use `{{...}}` for all Ruby expressions to make them explicit
- For complex conditions, consider creating a dedicated step that returns a boolean
- For collections, ensure they return iterable objects (arrays, hashes, etc.)
- Always set reasonable `max_iterations` limits on repeat loops
- Use meaningful variable names in `each` loops