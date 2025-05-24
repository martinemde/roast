# Conditional Execution in Roast Workflows

This example demonstrates how to use conditional execution (`if` and `unless`) in Roast workflows.

## Overview

Conditional execution allows workflows to execute different steps based on runtime conditions. This feature supports:

- `if` conditions - execute steps when a condition is true
- `unless` conditions - execute steps when a condition is false  
- `then` branches - steps to execute when the condition matches
- `else` branches - steps to execute when the condition doesn't match (optional, only for `if`)

## Syntax

### If Statement

```yaml
- if: "{{expression}}"
  then:
    - step1
    - step2
  else:
    - step3
    - step4
```

### Unless Statement

```yaml
- unless: "{{expression}}"
  then:
    - step1
    - step2
```

## Condition Types

Conditions can be:

1. **Ruby Expressions** - Wrapped in `{{...}}`
   ```yaml
   - if: "{{output.previous_step.success == true}}"
   ```

2. **Bash Commands** - Wrapped in `$(...)`
   ```yaml
   - if: "$(test -f /path/to/file && echo true || echo false)"
   ```

3. **Step References** - Reference to previous step output
   ```yaml
   - if: "check_condition"  # References a previous step
   ```

4. **File Checks**
   ```yaml
   - if: "{{File.exist?('/tmp/myfile.txt')}}"
   ```

## Examples

### Basic Example

```yaml
name: Conditional Example
tools:
  - Roast::Tools::Cmd

steps:
  - check_status: "echo 'success'"
  
  - if: "{{output.check_status.strip == 'success'}}"
    then:
      - success_action: "echo 'Operation succeeded!'"
    else:
      - failure_action: "echo 'Operation failed!'"
```

### Unless Example

```yaml
name: Unless Example
tools: []

steps:
  - check_file: "test -f /tmp/important.txt && echo exists || echo missing"
  
  - unless: "{{output.check_file.strip == 'exists'}}"
    then:
      - create_file: "touch /tmp/important.txt"
      - notify: "echo 'Created missing file'"
```

### Nested Conditionals

```yaml
name: Nested Conditionals
tools: []

steps:
  - outer_check: "echo 'true'"
  - inner_check: "echo 'false'"
  
  - if: "{{output.outer_check.strip == 'true'}}"
    then:
      - if: "{{output.inner_check.strip == 'true'}}"
        then:
          - both_true: "echo 'Both conditions are true'"
        else:
          - only_outer: "echo 'Only outer condition is true'"
    else:
      - outer_false: "echo 'Outer condition is false'"
```

### Platform-Specific Actions

```yaml
name: Platform Detection
tools:
  - Roast::Tools::Cmd

steps:
  - detect_os: "uname -s"
  
  - if: "{{output.detect_os.strip == 'Darwin'}}"
    then:
      - mac_setup: "brew --version || echo 'Homebrew not installed'"
    else:
      - if: "{{output.detect_os.strip == 'Linux'}}"
        then:
          - linux_setup: "apt-get --version || yum --version"
        else:
          - unknown_os: "echo 'Unknown operating system'"
```

## Best Practices

1. **Use Clear Conditions**: Make your conditions explicit and easy to understand
2. **Handle Edge Cases**: Always consider what happens when conditions fail
3. **Test Both Branches**: Ensure both `then` and `else` branches work correctly
4. **Avoid Deep Nesting**: Keep conditional logic simple and readable
5. **Use Unless Sparingly**: `unless` can be less intuitive than `if` with negation

## Debugging

To debug conditional execution:

1. Check the workflow output to see which branch was executed
2. Look for keys like `if_condition_name` or `unless_condition_name` in the output
3. These keys contain information about the condition evaluation and branch taken

## Running the Example

```bash
# Run the simple conditional example
roast execute examples/conditional/simple_workflow.yml

# Run the full conditional example (requires API configuration)
roast execute examples/conditional/workflow.yml
```